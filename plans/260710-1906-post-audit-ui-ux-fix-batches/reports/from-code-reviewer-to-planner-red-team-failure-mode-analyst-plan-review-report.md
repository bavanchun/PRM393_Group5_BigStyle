# Red-Team Plan Review — Failure Mode Analyst

Plan: `plans/260710-1906-post-audit-ui-ux-fix-batches/` @ dev `fab9a26`
Role: FLOW TRACER — all behavioral claims traced through actual code paths.
Verdict: plan's factual line-number claims are mostly accurate; its OTP design (phases 4–5) has one unimplementable-as-scoped requirement, two stale-state traps, and a false concurrency invariant. Batch 1 has inventory gaps its own guard greps cannot detect.

Key traced paths (baseline):

- Submit path: `otp_input.dart:98-109` onChanged → only `index==5 && value.isNotEmpty` fires `widget.onCompleted` (`:103-108`) → `login_screen.dart:298-302` picks email via `state is AuthOTPSent ? state.email : _emailController.text.trim()` → `VerifyOTPEvent` → `auth_bloc.dart:60-75`: `AuthLoading` → `verifyOtp` → `AuthSuccess` | `AuthError('Mã OTP không hợp lệ')` | catch-all `AuthError('Xác thực thất bại')`.
- Send path: `auth_bloc.dart:50-58`: `AuthLoading` → `AuthOTPSent(email)` on success, `AuthError('Gửi mã OTP thất bại: ${e}')` on failure. Cooldown keyed to `AuthOTPSent` correctly never starts on send failure (plan got this right).
- Error sink: `login_screen.dart:78-85` — ONE undifferentiated `AuthError` branch for all six producer paths.

---

## Finding 1: Clear-on-`AuthError` cannot distinguish verify errors — wipes typed OTP on resend/Google failures; unimplementable correctly within plan scope

- **Severity:** Critical
- **Location:** Phase 4, "Requirements" (clear-on-error bullet) + "Implementation Steps" step 2; conflicts with plan.md "Overview" scope line ("no bloc events")
- **Flaw:** Phase 4 wires `_otpKey.currentState?.clear()` "on AuthError while in the OTP step". `AuthError` is a single cause-agnostic state emitted by six handlers: send failure (`auth_bloc.dart:56`), verify failure (`:70,:73`), password sign-in (`:92,:95`), Google (`:109,:115`), session check (`:43`), profile update (`:167`). `login_screen.dart:78-85` has one `AuthError` branch with no discriminator; `AuthError` carries only `message` (`auth_state.dart:49-55`). While `_showOtp == true`, the Google button (`login_screen.dart:114`, always rendered), debug test-login buttons (`:115-118`), and the resend link (`otp_input.dart:116-130`) are all live — every one of their failures emits `AuthError`.
- **Failure scenario:** User has typed 4 of 6 digits, taps "Gửi lại mã", Supabase returns 429 (the exact rate-limit situation G10 exists for) → `AuthError('Gửi mã OTP thất bại…')` → listener sees `_showOtp==true` → `clear()` wipes the 4 digits and yanks focus to box 0. A *send* failure destroys *verify* input. Same for a failed Google attempt tapped from the OTP step. Phase 5 promotes resend into a countdown-gated first-class action, increasing traffic through exactly this path.
- **Evidence:** `FE/lib/blocs/auth/auth_bloc.dart:56,70,73,92,95,109,115,167`; `FE/lib/screens/auth/login_screen.dart:78-85,106-118`; `FE/lib/screens/auth/otp_input.dart:116-130`; plan.md:24 forbids bloc changes, so the implementer cannot add an `AuthVerifyError` state or error-kind field without violating plan scope. Matching on `state.message` strings is the only in-scope option — brittle and Vietnamese-copy-coupled.
- **Suggested fix:** Amend plan scope to allow a minimal bloc-state discriminator (e.g., `AuthError.kind` enum or distinct `AuthOtpVerifyError extends AuthError` — backward compatible, all existing `is AuthError` checks keep working), and gate `clear()` on it. Alternatively track "last dispatched event was verify" in `_LoginScreenState` and gate on that; document whichever is chosen in phase file.

## Finding 2: `_lastSubmitted` guard + `clear()` = silent dead-end when user retypes the identical code after an error

- **Severity:** High
- **Location:** Phase 4, "Architecture" ("a simple `_lastSubmitted` string compare suffices") + "Requirements" (`clear()` spec) + step 3 test matrix
- **Flaw:** `clear()` is specified as "empties all boxes + focuses box 0" — nothing resets `_lastSubmitted`. After a verify error, `clear()` runs (Finding 1 path), user retypes the SAME 6 digits → `_maybeSubmit` computes `code == _lastSubmitted` → suppressed → no `VerifyOTPEvent`, no `AuthLoading`, no error, no spinner. Six filled boxes, dead UI.
- **Failure scenario:** Transient network failure during verify → catch-all `AuthError('Xác thực thất bại')` (`auth_bloc.dart:72-74` — cause is hidden, so retrying the same code is the rational user move) → boxes cleared → user carefully retypes the same correct code → nothing happens. Only escapes: edit a digit twice, or tap resend — which under Phase 5 starts a 60s cooldown, compounding the lockout. The Phase 4 test matrix (step 3) has no "clear → retype same code → resubmits" case, so the plan's own tests will pass while shipping this.
- **Evidence:** Phase-04 lines 23, 29-30 (guard + clear spec, no reset); phase-04 step 3 (five tests, none cover post-clear same-code resubmit); `auth_bloc.dart:72-74` (opaque catch-all encouraging same-code retry). Guard also suppresses the G15 fix's own edge: clear box 2, retype the *same* digit → no re-submit, contradicting requirement "Any change that results in all 6 boxes filled → submit".
- **Suggested fix:** Spec `clear()` to also reset `_lastSubmitted = null`; better, replace the string-compare guard with an edge-trigger (`_wasComplete` bool: fire only on transition incomplete→complete). Add the post-clear-retype test to the matrix.

## Finding 3: "Submit contract unchanged" is a false safety invariant — bloc 8.1.4 default transformer is concurrent flatMap; overlapping Send/Verify events corrupt global auth state consumed by 21 call sites

- **Severity:** High
- **Location:** Phase 4, "Overview" invariant + "Risk Assessment" ("mitigated: submit contract unchanged"); plan.md "Risks"
- **Flaw:** The plan's sole auth-path safety argument is that `onCompleted → VerifyOTPEvent` dispatch is unchanged. But bloc 8.1.4's default event transformer is `_FlatMapStreamTransformer` — **concurrent** (`~/.pub-cache/hosted/pub.dev/bloc-8.1.4/lib/src/bloc.dart:62-65,303`; `FE/pubspec.yaml:14` `bloc: ^8.1.4`), and `auth_bloc.dart:15-22` registers all handlers with no transformer. `SendOTPEvent` and `VerifyOTPEvent` in flight simultaneously interleave their emissions. Phase 4 (paste = instant submits) and Phase 5 (resend promoted with countdown) both increase send/verify overlap probability while adding listeners (`clear()` on AuthError, cooldown start on AuthOTPSent) that react to these cause-agnostic interleaved states.
- **Failure scenario:** Impatient user taps "Gửi lại mã" (send in flight — email-sending endpoint, slow) then pastes the code from the FIRST email → verify runs concurrently, succeeds first → `AuthSuccess` → `pushReplacementNamed('/home')` (`login_screen.dart:62-77`) + `CartLoad` (`main.dart:140-147`). Then the late `AuthOTPSent` (or a late `AuthError` from a lost race) lands: global AuthBloc state now has `user == null`. Every subsequent `context.read<AuthBloc>().state.user?.id` returns null — orders (`orders_screen.dart:31,54`), cart (`cart_screen.dart:42`), checkout (`checkout_screen.dart:316,331,397,497`), wishlist (`wishlist_actions.dart:11`), chat, favorites, notifications — user is logged in per Supabase but the app renders empty/guest data until something re-emits AuthSuccess. Secondary: `enabled: state is! AuthLoading` re-enables OTP boxes the moment the concurrent send emits `AuthOTPSent` mid-verify, letting the user fire yet another VerifyOTPEvent.
- **Evidence:** bloc-8.1.4 source line 62-65 (flatMap default); `FE/lib/blocs/auth/auth_bloc.dart:15-22` (no transformers); 21 `AuthBloc>().state.user` read sites (grep verified); `FE/lib/main.dart:140-147`; `edit_profile_screen.dart:25-26` comment proves this codebase already got bitten by cross-cause auth emissions once.
- **Suggested fix:** Plan must either state the race explicitly with a mitigation (disable resend link while `AuthLoading`, i.e., `resendEnabled: cooldown==0 && state is! AuthLoading` — cheap, widget-layer, in scope) or drop the "submit contract unchanged ⇒ safe" claim and add `droppable()` transformer to send/verify handlers as an allowed scope amendment.

## Finding 4: Phase 1 inventory incomplete — a third live VND formatter survives, and both guard greps are structurally blind to it

- **Severity:** High
- **Location:** Phase 1, "Requirements" (DRY: "delete the two existing manager-side local formatters"), "Architecture" ("unifies 3 coexisting styles into 1"), step 4 guards
- **Flaw:** `manager_voucher_list_screen.dart:155-163` contains a fourth hand-rolled formatter `_formatVnd` (manual `StringBuffer` dot-grouping) used at `:152` to render `Giảm 20.000đ`. It is absent from Related Code Files. Both guard greps miss it: `toStringAsFixed\(0\)\}? ?đ` fails because `:156` has `toStringAsFixed(0)` with no `đ` on the same line (đ is appended at `:152` around the helper call), and the `NumberFormat` grep fails because it uses no NumberFormat. Additionally `admin_dashboard_screen.dart:293-296` renders VND revenue as `'… tỷđ'/'… triệuđ'` (`toStringAsFixed(1)`) — outside the sweep and unmentioned, contradicting "used everywhere a VND amount is displayed" (if compact notation is intentionally exempt, the phase must say so).
- **Failure scenario:** Phase completes, all success criteria green (greps 0, tests pass, emulator spot-check on customer screens fine) — yet the codebase still has two independent VND formatters plus a private `_formatVnd` whose name now collides semantically with the new global `formatVnd` (theirs returns WITHOUT the đ suffix — a future import swap silently double-suffixes or drops đ). The phase's core requirement fails while its verification passes: phantom guard.
- **Evidence:** `FE/lib/screens/manager/vouchers/manager_voucher_list_screen.dart:152,155-163`; `FE/lib/screens/admin/admin_dashboard_screen.dart:293-296`; grep of `toStringAsFixed` across FE/lib (28 hits; plan's 17 customer-side hits verified accurate, the misses are the manager-voucher + admin-dashboard clusters).
- **Suggested fix:** Add `manager_voucher_list_screen.dart` `_formatVnd` deletion (replace `'Giảm ${_formatVnd(v)}đ'` with `'Giảm ${formatVnd(v)}'`) to Related Code Files; explicitly declare admin compact-revenue notation in/out of scope; add a third guard grep for `đ'` string interpolation or at minimum note the blind spot.

## Finding 5: Phase 2's "5 FABs" claim is false — 6th default-tag FAB at delivery_map_screen.dart:364; success-criterion grep is scoped to never see it

- **Severity:** Medium
- **Location:** Phase 2, "Overview" ("Currently 5 FABs use Flutter's default tag") + "Requirements" ("no hero-tag collisions anywhere") + Success Criteria grep
- **Flaw:** `grep FloatingActionButton FE/lib` returns SIX: the five listed plus `FE/lib/screens/delivery/delivery_map_screen.dart:364` (`FloatingActionButton.small` — all FAB constructors share the same `_DefaultHeroTag`). The success-criterion grep is restricted to `FE/lib/screens/{admin,manager}`, so the miss is invisible to the phase's own verification, and the requirement "no collisions anywhere" is unmet by design.
- **Failure scenario:** Latent today (delivery map is only pushed from profile, `profile_screen.dart:130`, no FAB beneath). The first future screen with a FAB that pushes or sits under `/delivery-map` reproduces the exact assertion this phase claims to eliminate — with the plan on record saying the sweep was complete.
- **Evidence:** grep output: 6 `FloatingActionButton` construction sites, 0 existing `heroTag` in FE/lib; `FE/lib/config/routes/app_router.dart:55-56`; `FE/lib/screens/profile/profile_screen.dart:130`.
- **Suggested fix:** Add `heroTag: 'delivery-map-fab'` as a 6th line; widen the guard grep to all of `FE/lib` with expected count 6.

## Finding 6: Whole-plan AC "boxes disabled + spinner during verify" is unimplementable from Phase 4's spec — no spinner exists or is added in the OTP step

- **Severity:** Medium
- **Location:** plan.md "Acceptance Criteria" (OTP bullet) vs Phase 4 "Requirements"/"Implementation Steps"
- **Flaw:** During verify, `_showOtp == true`, so the only loading indicator in the screen — the send button's `CircularProgressIndicator` (`login_screen.dart:263-271`) — is not rendered (`:106-110` renders `_buildOtpSection` instead). Phase 4 adds only the `enabled` param; neither requirements nor steps nor tests add any spinner/indicator to the OTP section. Result as specified: verify in flight = six greyed boxes and nothing else. G18 ("no loading feedback") is only half-closed; the plan-level AC cannot be checked off by executing the phase as written.
- **Failure scenario:** Implementer either fails the AC at closeout or improvises unspecified UI (scope drift on the auth path — precisely what this plan's review gates are supposed to prevent).
- **Evidence:** `FE/lib/screens/auth/login_screen.dart:106-110,263-271`; phase-04 requirements list (lines 18-25) and step list (36-47) — zero mention of a loading indicator element; plan.md:45.
- **Suggested fix:** Spec it: e.g., resend-link slot swaps to a 16px spinner + "Đang xác thực…" while `state is AuthLoading` (layout-stable, matches Phase 5's no-jump constraint), and add it to the widget test list.

## Finding 7: Rollback and independence claims are false — phases 4/5 and 1/3 have entangled files; "surgical revert" leaves compile breaks

- **Severity:** Medium
- **Location:** plan.md "Risks" ("1 phase = 1 commit → surgical revert") and "Phases" ("Phases 1–3 are independent of each other")
- **Flaw:** (a) Phase 5 modifies both `otp_input.dart` (adds `resendEnabled`/`resendLabel`) and `login_screen.dart` on top of Phase 4's rework; Phase 5 code references Phase 4 symbols (`GlobalKey<OtpInputState>`, `enabled` param, public `OtpInputState`). Reverting the Phase 4 commit after Phase 5 lands = merge conflict or non-compiling tree — not surgical. (b) Phases 1 and 3 both edit `manager_dashboard_widgets.dart`: Phase 1 rewrites line 25 (`formatOrderCurrency(stats.todayRevenue)` → `formatVnd` + import swap), Phase 3 edits lines 33/90/100 of the same two widget bodies — 8 lines apart, same diff hunk context. They are not independent; a Phase 1 revert after Phase 3 conflicts.
- **Failure scenario:** Phase 4 causes an auth regression discovered after Phase 5 ships → `git revert <phase4>` fails or breaks build → rollback under pressure becomes a manual re-edit of the auth path, the exact scenario the risk section claims is covered.
- **Evidence:** `FE/lib/screens/manager/manager_dashboard_widgets.dart:25,33,90,100`; phase-01 Related Code Files (`manager_dashboard_widgets.dart:25`) vs phase-03 Related Code Files (same file `:33,:88-91,:96-104`); phase-05 Related Code Files lists both `login_screen.dart` and `otp_input.dart`.
- **Suggested fix:** State honestly: rollback unit for the OTP cluster is phases 4+5 together (revert both commits, newest first); order Phase 3 after Phase 1 explicitly or merge their dashboard-widget edits into one phase.

## Finding 8: Phase 5 cooldown keyed to screen not email — self-inflicted 60s lockout after typo correction; resend path bypasses the new validator entirely

- **Severity:** Medium
- **Location:** Phase 5, "Architecture" (cooldown state in `_LoginScreenState`) + "Requirements" (validator matrix)
- **Flaw:** (a) The email field remains editable during the OTP step (`login_screen.dart:104` — always rendered; `_showOtp` never resets). Cooldown is a single screen-level counter started on any `AuthOTPSent`. Supabase rate-limits per identifier; the plan blocks sends to a *different* email for the residual window. (b) The resend path `login_screen.dart:304-309` guards only `email.isNotEmpty` — no `_formKey` validation. Phase 5 swaps the validator at `:230-233` and gates `_sendOtp()` at `:415-418`, but resend dispatches `SendOTPEvent(_emailController.text.trim())` unvalidated. (c) Related: on any post-error resubmit, `onCompleted`'s email source falls back to raw controller text (`login_screen.dart:299-301` — state is `AuthError`, not `AuthOTPSent`), so an edited email mid-step verifies the code against the wrong address → guaranteed opaque "Xác thực thất bại" loop; Phase 4's clear-on-error funnels more traffic into exactly this fallback branch.
- **Failure scenario:** User sends OTP to `hoangbavan4478@gmial.com` (typo), instantly notices, fixes the field → "Gửi lại sau 58s" blocks the *correct* address for a minute — a lockout that does not exist today. Separately: user blanks/mangles the email field to `a@` mid-step, waits out cooldown, taps resend → raw Supabase error surfaced via `AuthError` snackbar — falsifying plan.md AC "email validator rejects `a@`" — and (Finding 1) wiping any typed digits.
- **Evidence:** `FE/lib/screens/auth/login_screen.dart:104,230-233,299-309,415-418`; `FE/lib/blocs/auth/auth_bloc.dart:50-58`; plan.md:46.
- **Suggested fix:** Track `_cooldownEmail`; reset cooldown when the trimmed field no longer equals it. Route resend through `validateEmail` (or lock the email field while `_showOtp`, with an explicit "đổi email" affordance that resets `_showOtp` and cooldown — also fixes the wrong-email verify fallback).

---

## What survived attack (verified accurate, no finding)

- Phase 1's 17 customer-side occurrence list: exact match against grep @ fab9a26. All price fields are non-nullable `double` (`order_model.dart:78-80`, `cart_item_model.dart:33`, `checkout_screen.dart:323,403` coalesce with `?? 0` before display) — `formatVnd(num)` non-null signature is safe; no negative-amount display paths exist.
- Phase 1's "no locale init needed" claim: proven by `manager_order_card.dart:11-15` (NumberFormat with `vi_VN` already runs in prod code).
- Phase 3 line refs (`:33` success color, `:90` caption label, `:100-103` displaySmall value) and typography claims (caption=w400/textHint `app_typography.dart:109-115`, labelSmall=w500/textSecondary `:100-107`) all verified.
- Phase 5 cooldown correctly starts only on `AuthOTPSent` — send failure does NOT lock the user out (traced `auth_bloc.dart:50-58`).
- Phase 5 regex passes its stated accept/reject matrix including `+alias` (checked by inspection).
- G13/G14/G15/G16 diagnosis of `otp_input.dart` is accurate (`:56` maxLength swallows paste; `:103` only box-5 submits; `:82-86` border reads controller text with no setState anywhere in `:98-109`).

## Unresolved questions

1. Is a minimal AuthBloc state addition (error discriminator, Finding 1) an acceptable scope amendment, or must clear-on-error be dropped from Phase 4?
2. Is admin compact revenue notation (`tỷđ/triệuđ`) intentionally out of Phase 1 scope?
3. Where does the `hardcode-guard` live? Not found under `FE/tool`, `tool/`, `scripts/` — plan.md AC references it at every phase boundary; if it flags raw `fontFamily: 'Montserrat'` the Phase 3 non-token variant must be deleted from the phase file, not offered as an option.

Findings: 1 Critical, 3 High, 4 Medium.
