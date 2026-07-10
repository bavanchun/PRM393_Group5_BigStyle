# BigStyle UI/UX Post-Reskin Assessment & Red-Team Fix Plan

**Date**: 2026-07-10 · 18:27–21:00 (Asia/Saigon)  
**Branch**: dev @ `fab9a26` (post-reskin merge, no code changed this session)  
**Plan**: `plans/260710-1906-post-audit-ui-ux-fix-batches/` (5 phases, red-teamed, ready to cook)  
**Reports**:
  - QA audit: `plans/reports/qa-260710-1827-post-reskin-full-app-emulator-audit-report.md`
  - Assessment: `plans/reports/brainstorm-260710-1906-ui-ux-current-state-assessment-post-reskin-report.md`
  - Red-team: `plans/260710-1906-post-audit-ui-ux-fix-batches/reports/` (3 reviewer reports)

---

## What Happened

Four-stage arc, docs/plans only: (1) full-app post-reskin QA on Pixel 8 AVD — all 3 roles + guest, driven via adb/uiautomator with live log watching; (2) whole-app UI/UX current-state assessment — re-verified all 111 historical findings of `docs/ux-flow-audit.md` (03/07) against current code by grep + code-reading; (3) drafted a 5-phase fix plan (currency formatting, FAB heroTags, stat-card tokens, OTP input UX, resend cooldown + email validation); (4) red-team gate with 3 parallel hostile reviewers (Security Adversary/Fact Checker, Failure Mode Analyst/Flow Tracer, Assumption Destroyer/Scope Auditor) — 22 raw findings → 16 after dedup → 13 accepted (1 Critical, 5 High, 7 Medium), 1 partial, 2 rejected. All accepted findings applied to the plan files. **User deliberately stopped before implementation** — hardening the spec was the session's work product.

---

## The Brutal Truth

**The plan was wrong in ways that would have shipped bugs, and the author (me) didn't catch them.**

I wrote the plan with line-level citations from first-hand verification — 37 of 41 sampled citations were independently confirmed accurate by a reviewer. But accuracy ≠ completeness. Red-team found a Critical spec bug and two materially wrong inventories:

- The drafted `_lastSubmitted` string-compare guard (meant to stop paste double-fire) would have **bricked identical-code retry**: verify fails transiently → `clear()` (which never reset the guard) → user re-enters the same correct code → submit silently suppressed — on the ONLY submit path the OTP screen has. Worse, the guard defended a non-threat: programmatic `controller.text` writes don't fire `onChanged`, so paste distribution can't double-fire in the first place.
- FAB inventory: 5 of 6 (missed `delivery_map_screen.dart:364`, and my success-criteria grep was scoped so it could never catch the miss).
- Currency-formatter inventory: 2 of 4 (missed voucher-list `_formatVnd` — which name-shadows the planned shared helper — and the admin dashboard `_formatCurrency` grouping branch; both structurally invisible to the guard greps I'd specified).

**And I recommended skipping this red-team** ("plan is small/mechanical, evidence first-hand"). The user overrode that recommendation. The override paid for itself.

**Separately: the app has left "flow-breaking bugs" territory.** Re-verification showed ALL P0s and nearly all P1s from the 111-finding audit already fixed by prior waves (stability-hardening, qa-findings-fix, visual-reskin). What remains is polish plus one cohesive neglected cluster: auth/onboarding (2.5/5 — OTP boxes can't paste, no backspace-back, no cooldown, `contains('@')` email validation).

---

## Technical Details

### QA Audit (emulator, all roles)

Static gates clean post-merge: `flutter analyze` 0, `flutter test` 43/43. Found 2 High **pre-existing** bugs (not reskin-caused):
1. **Unformatted VND prices** at 17 call sites / 11 customer-side files — the entire purchase funnel shows `10000đ` instead of `10.000đ`. Only 2 manager-side files formatted correctly (and even those disagreed on style).
2. **Hero-tag collision** — `AdminShell`'s IndexedStack keeps 2 untagged FABs alive together → caught-but-real assertion in the log at every admin login (silent today, crash-class pattern).

Plus 1 Medium: manager stat-cards diverge from Admin's identical pattern (serif accent-tinted values, `textHint` labels). Also verified live: Cormorant renders Vietnamese diacritics correctly (closed a reskin-journal gap). To reach manager/customer roles, two seeded test-account passwords were reset via direct Supabase `auth.users` update — explicitly user-directed, same mechanism as the prior QA session; flagged for rotation.

### Assessment (111 findings re-verified)

Method: grep + code-reading per finding, cross-referenced against the fix history. Result: ~45 meaningful findings already fixed (all P0: splash hangs; nearly all P1: cart load, category filter, category-not-saved, silent status-update failures, orderNumber-vs-UUID, pending-order recovery…). Dimension scores: design system 4.5, core flows 4, navigation 4, error handling 3.5, consistency 3.5, **auth/onboarding 2.5** (weakest — G8/G10–G18 untouched by every fix wave).

### Red-Team Adjudication (the findings that changed the plan)

- **Critical — clear-on-AuthError is cause-agnostic:** `AuthError` is emitted by 6+ bloc handlers (send, verify, Google, signout). The drafted "clear boxes on AuthError" would wipe in-progress digits when a resend 429 or cancelled Google sign-in fires. Fix (widget-layer, keeps the no-bloc-changes scope): `_verifyInFlight` flag set around the `VerifyOTPEvent` dispatch — clear only when the error follows OUR verify; disable resend/Google/debug while in flight (which also supplies the missing loading affordance).
- **High — `_lastSubmitted` trap:** removed entirely (see Brutal Truth); regression test added to the spec: "clear then re-enter identical code must re-fire."
- **High — resend bypasses validation:** the resend closure dispatched `SendOTPEvent` gated only by `isNotEmpty`, while Supabase OTP send auto-creates accounts by default → junk-account surface. Fix: resend reuses `_sendOtp()` (validator + cooldown, one path). `shouldCreateUser` default documented as accepted residual.
- **High — cooldown spec wrong twice:** rationale ("60s matches GoTrue default") contradicted by the repo's own local `config.toml` (`max_frequency = "1s"`, 2 emails/hour); and success-only start allowed hammering failed sends. Fix: dispatch-started, per-email (`_cooldownEmail` — typo correction isn't locked behind the wrong address's timer), reworded as countdown-UX-only, rate-limit errors mapped to a friendly message. G10 recorded as "improved," not "closed."
- **High — `Timer.periodic` stacking:** `AuthOTPSent` re-fires per resend; without cancel-before-create the countdown ticks at 2x+. Fix: `_startCooldown()` cancels first, self-cancels at 0, mounted-guards.
- **High — formatter census 2→4** and **Medium — FAB census 5→6** (above), guard greps rewritten to be structurally capable of catching what they claim to check.
- **Medium (rest):** verify must target the `AuthOTPSent` email, not live field text (post-error email edits verified against the wrong address); main-button countdown AC was unverifiable (`_showOtp` never resets — button unmounted) → countdown moved to the resend link; paste >6 digits spec'd (prefer standalone `\b\d{6}\b` run — noisy clipboard "10/07/2026 — mã: 483920" must submit "483920", not "100720"); pending→warning would duplicate the product-card amber → product card moved to `StatusColors.info` (4 cards, 4 distinct token accents); "independent phases / surgical revert" softened (phases 1&3 share a file, phase 5 consumes phase-4 symbols → revert 5-before-4); spinner AC made implementable (resend slot swaps to "Đang xác thực…").
- **Partial:** bloc 8.1.4's default concurrent event transformer allows late auth states after `AuthSuccess` app-wide — pre-existing, not introduced by this plan; UI-side window closed via `_verifyInFlight` gating, bloc-level `droppable()` recorded as separate-plan candidate.
- **Rejected (with evidence):** "hardcode-guard script not found" — it exists at `FE/scripts/check_hardcoded_colors.sh`; the second reviewer verified it independently. Fact-fixes folded in: getters are `displayPrice`/`displayOriginalPrice`; theme getter is `AppTheme.light`; raw `fontFamily:` literal option dropped in favor of `AppTypography` tokens.

---

## Lessons Learned

1. **Verifying what you listed ≠ finding what you missed.** Citation accuracy was 37/41; inventory completeness was 5/6 (FABs) and 2/4 (formatters). Adversarial review hunts for absences; self-review re-confirms presences. Both censuses failed the same way: the verification grep was scoped to the files I already knew about.
2. **A guard is a spec liability until you name the threat it defends against.** `_lastSubmitted` defended paste double-fire — which cannot happen (programmatic writes don't fire `onChanged`) — while creating a real dead-end on the retry path. Threat-model first, then guard.
3. **Error-type cardinality is spec-relevant.** "Clear on AuthError" reads fine until you count the emitters (6+). Any spec keyed on a shared error type must say how it discriminates source — or use local state (in-flight flags) instead.
4. **Config files are part of the spec.** The "60s GoTrue default" claim died on contact with the repo's own `config.toml`. Rationales that cite external defaults need an in-repo citation or a hedge.
5. **Skip-the-gate recommendations can be confidently wrong.** The strongest argument for skipping ("evidence is first-hand") is exactly the condition under which the author's blind spots go unchallenged. Red-team on a "mechanical" plan cost ~30 minutes of wall-clock and removed a Critical.
6. **journal-writer output needs review, again.** Second consecutive session the subagent's draft contained fabricated specifics (invented finding descriptions, an invented rejected finding, wrong mitigation); rewritten by hand from session ground truth. Feed it facts, then diff its output against them.

---

## What Did NOT Happen (By Design)

- No code changed; no implementation attempted (user's explicit call — plan is staged for a later `/ck:cook`).
- No live OTP end-to-end verification (needs a real inbox; spec'd for the implementation phase).
- Old `plans/260703-1750-bigstyle-demo-fix-roadmap/` (status partial, largely superseded) left as-is — archive decision deferred.

---

**Status**: DONE  
**Summary**: One-evening arc: post-reskin emulator QA (2 High pre-existing bugs found, gates clean) → 111 old findings re-verified (~45 meaningful fixes confirmed landed; auth/onboarding is the weakest remaining cluster) → 5-phase fix plan drafted, red-teamed (16 findings, 1 Critical accepted), hardened, and parked ready-to-cook at user's request.
