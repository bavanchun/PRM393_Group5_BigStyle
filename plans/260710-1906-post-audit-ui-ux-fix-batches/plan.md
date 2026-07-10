---
title: "Post-audit UI/UX fix batches: currency, hero tags, stat-card, OTP UX"
description: "Fix 2 High + 1 Medium from qa-260710-1827 emulator audit (VND formatting funnel-wide, FAB hero collision, manager stat-card tokens) + OTP/auth UX cluster G8/G10-G18 still open from ux-flow-audit.md"
status: done
priority: P2
branch: "dev"
tags: [ui-ux, qa-followup, currency, otp, flutter]
blockedBy: []
blocks: []
created: "2026-07-10T12:44:43.143Z"
createdBy: "ck:plan"
source: skill
---

# Post-audit UI/UX fix batches: currency, hero tags, stat-card, OTP UX

## Overview

Executes "Batch 1 + Batch 2" from `plans/reports/brainstorm-260710-1906-ui-ux-current-state-assessment-post-reskin-report.md` (which re-verified all 111 findings of `docs/ux-flow-audit.md` against current code):

- **Batch 1 (phases 1–3):** the 2 High + 1 Medium findings from `plans/reports/qa-260710-1827-post-reskin-full-app-emulator-audit-report.md` — unformatted VND prices across the whole customer funnel, un-tagged FABs throwing a real Hero-collision assertion (6 FABs after red-team census correction), manager stat-card typography/color divergence (+ closes old M6: pending stat colored success-green).
- **Batch 2 (phases 4–5):** the OTP/auth UX cluster untouched by any prior fix wave — G8 (weak email validation), G10 (no resend cooldown — improved, not fully closed; see phase 5), G11/G13–G16/G18 (OTP boxes: no paste, no backspace-back, no re-submit after middle edit, stale filled-border, no loading/disable, no clear-on-error).

Scope is **widget-layer only** — no bloc events, no service calls, no navigation, no schema changes. (Red-team confirmed clear-on-error and error-message mapping are implementable at widget layer via a `_verifyInFlight` flag; the bloc-level concurrent-transformer limitation is documented, not fixed here.) Every phase ends with `flutter analyze` clean + `flutter test` green + ≥1 dedicated commit (user rule: mỗi phase ≥1 commit).

**Baseline:** `dev` @ `fab9a26` — analyze 0 issues, 43/43 tests, hardcode-guard 0.

## Phases

| Phase | Name | Status | Commit |
|-------|------|--------|--------|
| 1 | [Shared VND currency formatter](./phase-01-shared-vnd-currency-formatter.md) | Done | `8083ff0` |
| 2 | [FAB hero tags](./phase-02-fab-hero-tags.md) | Done | `cf5d616` |
| 3 | [Manager stat-card token alignment](./phase-03-manager-stat-card-token-alignment.md) | Done | `55bc5ca` |
| 4 | [OTP input UX](./phase-04-otp-input-ux.md) | Done | `2d9c334` |
| 5 | [OTP resend cooldown and email validation](./phase-05-otp-resend-cooldown-and-email-validation.md) | Done | `696dbd1` |

Execution order 1→5, strictly sequential (phases 1 and 3 edit different hunks of the same `manager_dashboard_widgets.dart`; 4 and 5 both touch `login_screen.dart`/`otp_input.dart`).

## Acceptance Criteria (whole plan)

- [ ] `grep -rnE "toStringAsFixed\(0\)\}? ?đ" FE/lib` → 0 AND `grep -rn "NumberFormat" FE/lib --include="*.dart" | grep -v utils/currency_format.dart` → 0; all price displays render `10.000đ` style (emulator: home card, product detail, cart, checkout, orders, manager voucher list). Documented exemption: admin dashboard compact `tỷ`/`triệu` wrapper (grouping branch delegates to `formatVnd`).
- [ ] All 6 FAB constructors in `FE/lib` carry a unique `heroTag`; admin login and manager voucher/category pushes produce no "multiple heroes" exception in `flutter run` log
- [ ] Manager dashboard stat values render bold sans `textPrimary`, labels `textSecondary`; 4 cards have 4 distinct accents (primary / warning / info / accent) with pending = `warning` (matches `StatusBadge` mapping)
- [ ] OTP: paste (incl. noisy clipboard → standalone 6-digit run) fills and auto-submits; backspace on empty box moves back; editing a middle box then completing re-submits; re-entering the identical code after clear re-submits; boxes + resend + Google + debug buttons disabled with "Đang xác thực..." spinner in the resend slot during verify; boxes cleared ONLY on verify-originated errors
- [ ] Resend link disabled with "Gửi lại sau {n}s" countdown for 60s per email (dispatch-started, single-rate tick, per-email bypass on address change); resend path goes through the validator; email validator rejects `a@`, `@b`, accepts `hoangbavan4478+admin@gmail.com`; verify targets the `AuthOTPSent` email, not live field text
- [ ] `flutter analyze` 0 issues, `flutter test` green (43 existing + new), hardcode-guard still 0, at every phase boundary

## Dependencies

- No hard cross-plan dependency. Related: `plans/260703-1750-bigstyle-demo-fix-roadmap/` (status partial) targeted the same 111-finding audit — most of its scope has since been delivered by other plans (stability-hardening, qa-findings-fix, visual-reskin); this plan covers the remaining OTP cluster + new QA findings. That roadmap is a candidate for archive, decided separately.

## Risks

- **Phase 4 touches the primary auth path.** Mitigation: verify/submit logic unchanged (`onCompleted → VerifyOTPEvent` as-is); dedicated regression tests for the two red-team traps (identical-code retry, noisy-clipboard paste); debug test-login flow (bypasses OTP) unaffected.
- **Phase 1 changes manager order-card format** from `40.000 đ` (space) to unified `40.000đ` — deliberate.
- **Revert order matters:** phase 5 consumes phase-4 symbols → revert 5 before 4. Phases 1/3 share a file (different hunks) → sequential execution, reverts independent.
- **Known limitation (out of scope):** `AuthBloc` uses bloc 8.1.4's default concurrent event transformer; overlapping send/verify at bloc level remains possible app-wide. Phase 4 closes the login-UI window (disables triggers during verify); a `droppable()` transformer is a separate-plan candidate.
- **Residual security note:** OTP send auto-creates accounts (`shouldCreateUser` default) and client cooldown is UX-only — server rate limits are the real guard; service changes out of scope, documented in phase 5.

## Red Team Review

### Session — 2026-07-10
**Reviewers:** Security Adversary (Fact Checker), Failure Mode Analyst (Flow Tracer), Assumption Destroyer (Scope Auditor) — 22 raw findings, 16 after dedup.
**Findings:** 16 (13 accepted, 1 partially accepted, 2 rejected/corrected-in-place)
**Severity breakdown:** 1 Critical, 5 High, 8 Medium, 2 fact-fixes
**Reports:** `reports/from-code-reviewer-to-planner-red-team-{security-adversary,failure-mode-analyst,assumption-destroyer}-plan-review-report.md`

| # | Finding | Severity | Disposition | Applied To |
|---|---------|----------|-------------|------------|
| A | clear-on-AuthError cause-agnostic (wipes digits on resend/Google errors) | Critical | Accept — `_verifyInFlight` flag + disable triggers during verify | Phase 4 |
| B | `_lastSubmitted` guard bricks identical-code retry; defends a non-threat | High | Accept — guard removed + regression test | Phase 4 |
| C | Resend path bypasses validator+cooldown (junk-account surface) | High | Accept — resend reuses `_sendOtp()` | Phase 5 |
| D | Verify falls back to live field text after error (wrong-email verify) | Medium | Accept — `_otpEmail` cache from `AuthOTPSent` | Phase 5 |
| E | Cooldown success-only start + "60s GoTrue default" contradicted by local config | High | Accept — dispatch-started cooldown, rationale reworded, rate-limit message mapped, G10 "improved" not "closed" | Phase 5 |
| F | `Timer.periodic` stacks per resend → 2x countdown | High | Accept — cancel-before-create, self-cancel, mounted guard | Phase 5 |
| G | Main-button countdown AC unverifiable (`_showOtp` never resets) | Medium | Accept — AC moved to resend link | plan.md, Phase 5 |
| H | Per-screen cooldown locks typo-corrected email | Medium | Accept — per-email `_cooldownEmail` bypass | Phase 5 |
| I | Paste >6 digits unspecified (wrong-code auto-submit) | Medium | Accept — standalone `\b\d{6}\b` preference, <6 → ignore | Phase 4 |
| J | FAB census wrong: 6 not 5 (`delivery_map_screen.dart:364`), grep too narrow | Medium | Accept — census 6, repo-wide grep | Phase 2, plan.md |
| K | 2 more local formatters missed (voucher `_formatVnd`, admin grouping branch); guards blind | High | Accept — inventory + guard greps rewritten; admin compact tỷ/triệu = documented exemption | Phase 1, plan.md |
| L | "Independent phases / surgical revert" overclaimed (shared files, symbol deps) | Medium | Accept — sequential-execution + revert-order notes | plan.md, Phases 1/3/5 |
| M | "Spinner during verify" AC unimplementable as drafted | Medium | Accept — spec'd: resend slot spinner + disabled boxes | Phase 4, plan.md |
| N | pending→warning duplicates 'Tổng sản phẩm' amber accent | Medium | Accept — product card moved to `StatusColors.info` | Phase 3 |
| O | Fact fixes: getters are `displayPrice`/`displayOriginalPrice`; `AppTheme.light` not `.lightTheme`; raw `fontFamily` option dropped | — | Accept | Phases 1, 3 |
| P | bloc 8.1.4 concurrent transformer → late states after AuthSuccess | High | Partial — pre-existing, bloc fix out of scope; UI window closed via `_verifyInFlight`; documented as known limitation | Phase 4, plan.md Risks |
| Q | "hardcode-guard script not found" (FMA) | — | Reject — exists at `FE/scripts/check_hardcoded_colors.sh`, verified by Assumption Destroyer and in-session | — |

### Whole-Plan Consistency Sweep
- Files reread: plan.md, phase-01…phase-05 (all rewritten this session, post-findings)
- Decision deltas checked: 9 (FAB count 5→6; formatter census 2→4 + exemption; `_lastSubmitted` removed; `_verifyInFlight` introduced; cooldown dispatch-started + per-email; countdown UI = resend link; product-card accent → info; getter/theme symbol fixes; revert-order note)
- Reconciled stale references: plan.md ACs (FAB count, spinner wording, resend countdown target, guard greps, accent set), phase-04/05 cross-references (`resendLabel` params, `_otpEmail` ownership), phase-01/03 shared-file notes
- Unresolved contradictions: 0

## Validation Log

### Implementation deviations (2026-07-10 execution)
Baseline `fab9a26` → head `696dbd1`; analyze 0, `flutter test` 64/64, hardcode-guard 0 at every phase boundary; all AC guard greps pass.
1. **Phase 1 — extra voucher call site.** The plan census listed only `manager_voucher_list_screen.dart:152`; a second call `_formatVnd(voucher.minOrderAmount)` at `:192` (min-order text) also fed the deleted local helper. Both switched to `formatVnd(...)` with the caller's trailing literal `đ` removed.
2. **Phase 1 — intl kept in product list.** `manager_product_list_screen.dart` uses `DateFormat` too, so `package:intl/intl.dart` was retained after deleting `_formatPrice` (only the `NumberFormat` usage went away).
3. **Phase 4 — digitsOnly formatter dropped.** The phase-4 architecture note suggested `FilteringTextInputFormatter.digitsOnly`, but formatters run before `onChanged`, stripping the separators the standalone-`\b\d{6}\b`-run heuristic needs (noisy paste `10/07/2026 — mã: 483920` would resolve to `100720` not `483920`). The formatter was omitted and single-char input is sanitized to a digit inside `_handleChanged` instead — the noisy-paste regression test passes.

Unresolved questions carried from red-team (do not block implementation, affect phase-5 verification expectations only):
1. Which Supabase environment the emulator build targets during phase-5 manual verification (hosted 60s window vs local-dev 1s/2-per-hour) — determines whether the rate-limit snackbar is reachable in testing.
2. `shouldCreateUser` default (implicit signup on OTP send) — accepted product behavior for now, revisit if junk accounts appear.
