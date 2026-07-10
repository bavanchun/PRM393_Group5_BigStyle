---
phase: 7
title: "Auth/Guest Cluster"
status: pending
effort: "M (half day, 2 screens)"
priority: P3
dependencies: [6]
---

# Phase 7: Auth/Guest Cluster

## Overview

Smallest, lowest-urgency cluster (2 screens) — last in the demo-visibility-ordered sequence since a grader typically sees the app already logged in during a demo, not the login screen itself. Closes out the plan.

## Screens (effort tags from Phase 4 cluster table)

| Screen | File | Effort | Findings source |
|---|---|---|---|
| Login | `FE/lib/screens/auth/login_screen.dart` (+ `otp_input.dart` component, embedded not a separate screen) | **L** — 6 findings including a contrast item | `phase-04-gap-findings-guest.md` |
| Splash | `FE/lib/screens/splash/splash_screen.dart` | S (inferred, never visually captured — session-cache routing makes it structurally uncapturable post-launch, not a bug) | Phase 1 code metrics only |

## Implementation Steps

1. Login: hardcode → token sweep (18 hardcode-lines per Phase 1 — the HIGHEST in the customer/guest set; DeliveryMap is 14). Note this screen also holds v1 pink hexes (`login_screen.dart:54,249`) that stay visibly stale until this last phase — acceptable only because work happens on the feature branch, not `dev` (see plan.md Execution Model). Re-check Login's contrast finding with a real WCAG tool before accepting/rejecting, same caveat as other clusters. <!-- Updated: Red Team Session 1 - the old sentence had the ranking inverted -->
2. Login: this screen owns the debug test-login buttons (`_buildDebugTestLoginButtons`) — `kDebugMode`-gated and invisible in release builds; migrate their styling too for dev-experience consistency. **Because this sweep rewrites the very file holding that gate, the success criteria below pin it: the `kDebugMode` guard and its call-site must be byte-identical pre/post reskin.** <!-- Updated: Red Team Session 1 - "zero risk" claim previously rested on a gate this phase itself edits around -->
3. `otp_input.dart` (embedded component, not a route): token sweep for its 6 characters-per-box UI; old-audit `G16` (focus/border state not updating on input) is a still-open-outside-scope code bug, not this plan's job — don't fix it here unless it's trivially adjacent to a token change you're already making, and if so, note it as a separate fix in the diff.
4. Splash: token sweep from code alone (7 hardcode-lines per Phase 1) — this screen is inherently hard to visually verify (routes instantly when a session is cached). Accept a code-only migration here; if a genuinely logged-out device/emulator state is available at QA time, do a quick visual spot-check, but don't block the phase on engineering a logged-out state artificially.
5. `flutter analyze`; `flutter test`.

## Regression Checklist

- [ ] Login: email input, OTP-send flow, OTP verification, debug test-login buttons (dev only) all function identically.
- [ ] Splash: routing logic (session-cached → role-appropriate home; no session → login) completely unchanged — this phase touches only colors/typography/shape, zero routing logic.

## Success Criteria

- [ ] Both screens migrated.
- [ ] Login's contrast finding resolved or confirmed-false-positive with real-tool measurement documented.
- [ ] The debug test-login `kDebugMode` gate and its call-site are unchanged by the sweep (diff-verified); optionally build `--release` and confirm the buttons are absent. <!-- Updated: Red Team Session 1 -->
- [ ] Hardcode-guard passes repo-wide now (this is the last cluster — zero **non-allowlisted** occurrences across all of `lib/screens` + `lib/widgets`, not just this cluster's files). <!-- Updated: Red Team Session 1 - allowlist-aware wording; raw zero was unachievable -->
- [ ] `flutter analyze` + `flutter test` clean.

## Whole-Plan Closeout (do this at the end of this phase, not a separate step)

- [ ] Re-run Phase 0's diff (`git diff <original-pinned-SHA>...HEAD -- FE/lib`) one more time — confirm every screen file that was ever touched across Phases 1-7 is accounted for in this plan's changes, nothing slipped through unreviewed.
- [ ] Confirm zero `app_router.dart` / `*_shell.dart` tab-array / `Navigator.push*` call-graph changes anywhere in the full diff (out-of-scope check from `plan.md`).
- [ ] **Rotate the shared QA-account password** used for role logins during this plan's QA passes (reset via Supabase SQL, same technique that set it) — the audit pipeline left a shared test password live on 3 QA-alias accounts; don't let it outlive the plan. Never commit dart-define credential values. <!-- Updated: Red Team Session 1 -->
- [ ] Merge `feat/visual-reskin` → `dev` per the Execution Model in plan.md (final rebase + full-app smoke first).
- [ ] Mark this plan's `plan.md` status `completed`.

## Risk Assessment

- **Splash genuinely can't be visually verified without extra engineering effort** (clearing app session state) → accept the code-only migration; this is a low-risk screen (7 hardcode lines, momentary display) — not worth the effort to force a visual QA loop.
