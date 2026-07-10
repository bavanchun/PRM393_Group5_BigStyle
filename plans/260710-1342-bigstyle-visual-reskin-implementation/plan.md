---
title: "BigStyle Visual Reskin — Implementation"
description: "Implements the Warm Terracotta identity (docs/design-tokens-v2.md) across all 30 inventoried screens. Flow/navigation unchanged — visual-only. Fed entirely by plans/260710-1158-ui-ux-overhaul-audit-pipeline/ artifacts."
status: pending
priority: P1
branch: "feat/visual-reskin" # work branch; integrates into dev per Execution Model
tags: [ui-ux, reskin, design-system, flutter]
blockedBy: []
blocks: []
created: "2026-07-10T13:42:00.000Z"
createdBy: "ck:plan"
source: skill
---

# BigStyle Visual Reskin — Implementation

## Overview

**Goal:** implement the approved Warm Terracotta identity across the app's UI layer. This plan does the Dart code changes the audit pipeline explicitly did NOT do.

**Source pipeline:** `plans/260710-1158-ui-ux-overhaul-audit-pipeline/` (completed 2026-07-10). Key artifacts this plan is fed by:

- [Brainstorm report](../reports/brainstorm-260710-1158-ui-ux-overhaul-skill-pipeline-report.md) — original scope decision.
- [Phase 1: Inventory & Debt Map](../260710-1158-ui-ux-overhaul-audit-pipeline/reports/phase-01-ui-inventory-debt-map.md) — 30-screen inventory, debt tiers T1/T2/T3.
- [`docs/design-tokens-v2.md`](../../docs/design-tokens-v2.md) — frozen token table, typography/shape/spacing/motion spec, `rubric-v1`.
- [Phase 4: Screen Gap Audit](../260710-1158-ui-ux-overhaul-audit-pipeline/reports/phase-04-screen-gap-audit-by-role.md) — per-screen findings, target component inventory, effort tags, migration clusters. Per-role detail: `phase-04-gap-findings-{guest,customer,manager,admin}.md` in the same reports dir.
- [Phase 5: Executive Summary](../260710-1158-ui-ux-overhaul-audit-pipeline/reports/phase-05-overhaul-audit-executive-summary.md) — risk debate + dispositions.

**Audited SHA:** `6e77ccfcc7572621729fd67efca277ef4d65dab4`. Screens were inventoried/captured/graded against this exact tree. **Phase 0 of this plan (below) is mandatory before any other phase starts**: diff current `dev` HEAD against this SHA; any changed screen file gets its Phase 4 findings re-verified (re-read the diff, re-capture+re-grade if the visual surface changed) before that screen's migration phase begins.

**Absorbed backlog:** this plan absorbs `plans/260703-1750-bigstyle-demo-fix-roadmap`'s deferred cosmetic backlog (token cleanup, `Colors.*` hardcode removal) — that roadmap's Phase 1 flagged these as deferred-to-future-reskin. Note: `.withOpacity` cleanup, also on that deferred list, is **already done** (Phase 1 of the audit pipeline confirmed 0 deprecated `.withOpacity` calls repo-wide, fully migrated to `.withValues`) — do not re-open that item.

## Out of Scope (hard constraint — user-locked decision)

- **Any navigation/flow change.** Route names, screen sequencing, shell-tab order, and back-stack behavior stay exactly as they are. A phase step that would touch `app_router.dart`'s route table, `manager_shell.dart`/`admin_shell.dart`'s tab order, or any `Navigator.push`/`pushNamed` call graph is out of scope for this plan — reject it, don't quietly do it "while we're in the file."
- Fixing the 5 still-open-outside-scope old-audit bugs (G16, M12, M21, M28, M34) as a goal in themselves — only touch them if they sit directly in a file this plan is already rewriting for token reasons, and even then keep the token diff and the bug fix as separate, clearly-labeled changes.
- Fixing the 2 tap-target bugs (cart CTA, manager FAB) as a goal in themselves — see Phase 0, they're a **verification prerequisite**, not a feature of this plan. If the root cause turns out to be non-trivial, split it to its own plan rather than absorbing it here.
- New features, new screens, or backend/API changes of any kind.
- **Motion/animation work.** `docs/design-tokens-v2.md` includes a motion stance and rubric-v1 has a `motion` finding type, but this plan ships color/typography/shape only — motion tokens (`AppMotion`) and animation polish are **explicitly deferred** to a follow-up, not silently dropped. <!-- Updated: Red Team Session 1 -->

## Execution Model <!-- Updated: Red Team Session 1 - the plan previously committed ~8.5 days of partial reskin straight to shared `dev` with no rollback story -->

- **Work branch:** all Phases 0-7 commit to `feat/visual-reskin`, cut from `dev` at Phase 0. `dev` never shows a half-migrated app: teammates and any mid-window demo see the old, consistent v1 skin until merge.
- **Drift handling (mechanism, not a conditional):** at every phase boundary, rebase the branch on latest `dev` (or merge `dev` in) and re-run Phase 0's diff against the audit SHA `6e77ccf` — any newly-drifted screen gets its findings re-verified before its cluster phase, and the guard script re-runs over already-completed clusters to catch reintroduced hardcodes.
- **Merge policy:** default = merge once, at Phase 7 closeout, after final rebase + full-app smoke. If a graded demo needs the new skin earlier, merging after any completed cluster phase is acceptable — but that knowingly puts a mixed palette on `dev` (migrated clusters terracotta, later clusters still pink); record the decision in the phase completion note.
- **Rollback:** unmerged branch = rollback is simply not merging. Within the branch, bug fixes are never fused with token sweeps (two-commit rule, Phases 3/5), so any single change reverts cleanly.

## Phases

| Phase | Name | Status |
|-------|------|--------|
| 0 | [Pre-flight: SHA Diff & Bug Triage](./phase-00-preflight-sha-diff-bug-triage.md) | Done (pending live-tap verification, non-blocking) |
| 1 | [Tokens v2 in Code + Hardcode Guard](./phase-01-tokens-v2-in-code-hardcode-guard.md) | Done |
| 2 | [Shared Component Layer](./phase-02-shared-component-layer.md) | Done |
| 3 | [Customer-Shop Cluster](./phase-03-customer-shop-cluster.md) | Pending |
| 4 | [Customer-Account Cluster](./phase-04-customer-account-cluster.md) | Pending |
| 5 | [Manager Cluster](./phase-05-manager-cluster.md) | Pending |
| 6 | [Admin Cluster](./phase-06-admin-cluster.md) | Pending |
| 7 | [Auth/Guest Cluster](./phase-07-auth-guest-cluster.md) | Pending |

## Dependency Chain

```
Phase 0 (SHA diff + bug triage) ──> Phase 1 (tokens in code)
Phase 1 ──> Phase 2 (shared components — StatusBadge needs Phase 1's StatusColors extension; product_card needs the new token values)
Phase 2 ──> Phase 3 (customer-shop) ──> Phase 4 (customer-account) ──> Phase 5 (manager) ──> Phase 6 (admin) ──> Phase 7 (auth/guest)
```

Cluster order is demo-visibility-first (per audit Phase 5 risk mitigation): customer-facing screens ship first so partial completion still upgrades what a grader/demo audience sees. Manager/admin (highest debt, lowest visibility) come after. Auth/guest last — smallest cluster (2 screens), lowest urgency.

## Acceptance Criteria (whole plan)

- [ ] Phase 0 diff confirms no undetected drift, or all drifted screens re-verified before their cluster phase starts; re-checked at every phase boundary per the Execution Model. <!-- Updated: Red Team Session 1 -->
- [ ] `FE/lib/config/theme/{app_colors,app_typography,app_theme}.dart` rewritten per `docs/design-tokens-v2.md`'s v1→v2 table plus the additive tokens (`onPrimary`, `shadow`, `StatusColors` extension); fonts bundled locally; hardcode-guard gate in place, with a recorded baseline, reaching zero non-allowlisted occurrences by plan end. <!-- Updated: Red Team Session 1 -->
- [ ] `StatusBadge` component built (tonal, OrderStatus-aware, `StatusColors`-driven); orphaned `size_selector.dart` deleted; ProductDetail's inline size-selector block reworked tonal; `product_card.dart` reworked (4 radii + 5 font calls). <!-- Updated: Red Team Session 1 -->
- [ ] All 30 inventoried screens migrated (or explicitly deferred with reason, not silently dropped).
- [ ] Every cluster phase passes its regression checklist + `flutter analyze` + `flutter test` before being marked done.
- [ ] No flow/navigation changes anywhere in the diff (spot-check `app_router.dart`, `*_shell.dart` tab arrays are untouched).
- [ ] Real WCAG-tool contrast re-check done for **every audit-flagged contrast finding** (ProductDetail ×2, Profile, Chat, ManagerVoucherList, AdminDashboard, Login) plus ≥1 spot-check per cluster — not all 30 screens; the audit's Gemini-cited numbers are never reused. <!-- Updated: Red Team Session 1 - the old per-screen wording demanded ~30 unbudgeted re-checks -->

## Risk Assessment

- **Dev drift between audit and implementation** (team repo, no freeze) → Phase 0 diff at start + mandatory re-diff and guard re-run at every phase boundary (Execution Model) — the plan will span multiple days, so drift checking is a scheduled mechanism, not a conditional. <!-- Updated: Red Team Session 1 -->
- **Tap-target findings (cart CTA, manager FAB) block their screens' migration verification** → Phase 0 human-tap-checks these first (code reading contradicts both occlusion hypotheses — likeliest verdict is an adb-capture artifact, which dissolves both); if a real root-cause is non-trivial, split to a separate plan rather than stalling this one. <!-- Updated: Red Team Session 1 -->
- **Font swap** (Playfair Display+DM Sans → Cormorant+Montserrat) → `google_fonts` fetches at RUNTIME, not at `pub get`; an offline demo device silently falls back to Roboto. Mitigation: Phase 1 bundles the TTFs as local assets, disables runtime fetching, and smoke-tests with network off. <!-- Updated: Red Team Session 1 - previous mitigation ("one-time asset cache via pub get") was factually wrong -->
- **Contrast-ratio audit numbers are unreliable** (Phase 4/5 finding) → every phase's QA net requires a real WCAG-tool re-check, not reuse of audit-cited numbers.
- **Inherited audit claims can be stale even at zero git-drift** (red team proved M2 overtaken and M34's numbers wrong at the very SHA the audit graded) → Phase 0 re-verifies every inherited `closes {ID}` citation before cluster phases trust it. <!-- Updated: Red Team Session 1 -->

## Red Team Review

### Session 1 — 2026-07-10
**Reviewers:** Security Adversary (+Fact Checker), Failure Mode Analyst (+Flow Tracer), Assumption Destroyer (+Scope Auditor), Scope & Complexity Critic (+Contract Verifier) — 4 parallel hostile subagents, full reports in `./reports/from-code-reviewer-to-planner-red-team-*-plan-review-report.md`.
**Raw findings:** 35 → deduplicated to 15. **Accepted:** 14 (2 modified). **Rejected:** 1.
**Severity (consolidated):** 4 Critical, 6 High, 5 Medium. All 15 passed the evidence filter (file:line citations verified).
**Verification volume:** ~109 plan claims grep-checked against the pinned SHA across the 4 reviewers; all v1/v2 token values, screen paths, and per-file audit counts verified exact — failures were concentrated in the guard script, Phase 2's targets, and inherited audit claims.

| # | Finding | Severity | Disposition | Applied To |
|---|---------|----------|-------------|------------|
| 1 | Guard script unsound: mixed-line false negatives (`grep -v AppColors` hid 6 real violations), CWD fail-open (exit 0 scanning nothing from `FE/`), blind to legacy `GoogleFonts.*` calls | Critical | Accept | Phase 1 (script rewritten) |
| 2 | "Zero hardcode" endpoint unachievable: no `onPrimary`/`shadow` tokens for ~130 legitimate uses; 13 `Colors.*` lines in the 8 "untouchable" shared widgets owned by no phase; manager companion widget files unowned; true baseline ≈208 not 195 | Critical | Accept | Phases 1, 5, 7, AC |
| 3 | Phase 2 targeted orphaned `size_selector.dart` (zero importers) — real tonal violations live in ProductDetail's inline copy + `chipTheme` | Critical | Accept | Phases 1, 2, 3 |
| 4 | No branch/rollback strategy — ~8.5 days of partial reskin straight onto shared `dev`; drift handling was one conditional sentence | Critical | Accept | plan.md Execution Model, Phases 0, 7 |
| 5 | `StatusBadge` contract wrong: claimed consumers already tonal; 4-value enum can't express 5-value OrderStatus; bare `Theme.of(context)` lacks success/warning slots; `M6` is a stat-card one-liner, not a badge | High | Accept (modified: redefined as OrderStatus-aware DRY consolidation on a `StatusColors` ThemeExtension, not cut entirely — the 4 duplicated `_getStatusColor` maps are real DRY value) | Phases 1, 2, 5 |
| 6 | `product_card.dart` enumeration wrong: 4 raw radii not 3; 5 direct `GoogleFonts.dmSans` calls unowned by any phase (most demo-visible widget would ship in the old font) | High | Accept | Phase 2 |
| 7 | Phase 0 tap-bug hypotheses mechanically impossible (Scaffold FAB can't be occluded; cart CTA has no Stack) — likeliest root cause is an adb-capture artifact; Phase 3/5 preconditions assumed "Phase 0 fixed" though Phase 0 is diagnose-only; dead step 6 | High | Accept | Phases 0, 3, 5 |
| 8 | Font-swap risk factually wrong: google_fonts runtime-fetches per device; offline demo silently falls back to Roboto, invisible to every QA gate | High | Accept | Phase 1, plan.md risk |
| 9 | Cart bug fix fused into token-migration commit — contradicts plan's own separate-changes rule, breaks revert isolation on the demo-critical funnel | High | Accept | Phases 3, 5 (two-commit rule) |
| 10 | Stale inherited audit claims at zero drift: M2 phantom (no `Colors.grey` left; prescribed fix would regress white-on-gradient header), M20 in criteria with no owning step, M34 counts now 1007/928 | High | Accept | Phases 0, 5 |
| 11 | QA credential hygiene: shared live-admin QA password never rotated at closeout; debug-button `kDebugMode` gate rewritten by Phase 7 with no release-absence check | Medium | Accept | Phase 7 closeout |
| 12 | WCAG AC overreach: "per screen" re-check ×30 vs ~7 budgeted flagged re-checks — checkbox theater or an unbudgeted day | Medium | Accept | plan.md AC |
| 13 | "Optional" refactors inside step lists (ProductFormBody, admin NavigationBar extraction) invite scope leak | Medium | Accept | Phases 5, 6 |
| 14 | Motion spec silently dropped (rubric-v1 has a `motion` type; no phase implements or defers it) | Medium | Accept (explicit deferral) | plan.md Out of Scope |
| 15 | Relax sequential dependency chain / merge Phases 6+7 for parallel team execution | Medium | **Reject** — execution model is a single implementer working sequentially; the chain IS the QA mechanism (each cluster's regression gate runs on a stable base). Cluster order is also user-locked. Evidence was real but the premise (5 parallel implementers) doesn't match how this plan will be executed. | — |

Numeric/text corrections bundled into the accepted findings: Login 18 > DeliveryMap 14 (Phase 7 ranking inverted), audit per-file counts demoted to "context only — checklist = live guard output" in every cluster phase.

### Whole-Plan Consistency Sweep
- Files reread: plan.md + all 8 phase files (post-application).
- Decision deltas checked: 14 (accepted findings) — grep-swept for stale terms (`size_selector` as build target, `965/1033`, "one PR/commit", `BadgeStatus` enum, "195" as authoritative baseline, `grep -v AppColors`, `:196-207`, "2nd-highest after DeliveryMap").
- Reconciled stale references: 3 caught in the sweep itself (plan.md dependency-chain line still listing `size_selector` as a Phase 2 build target; plan.md frontmatter `branch: dev` contradicting the new Execution Model; Phase 5 overview citing "~78 of ~195" without the guard-baseline caveat) — all fixed.
- Unresolved contradictions: **0**. Remaining mentions of superseded values are intentional history notes inside correction text.

## Validation Log

### Session 1 — 2026-07-10
**Trigger:** `/ck:plan validate` run back-to-back with red-team per user request; user delegated full decision authority ("bạn toàn quyền quyết định") — questions answered by the controller under that delegation, each with recorded rationale, instead of an interactive interview. No user-locked decision was altered.
**Questions asked:** 8

#### Verification Results
- **Tier:** Full (8 phases) — per the workflow's guard, the codebase verification pass is covered by Red Team Session 1's evidence (~109 claims grep-checked by 4 reviewers; see reports dir). No `[UNVERIFIED]` tags existed in the plan.
- Supplementary checks run for this session: `.github/workflows/` does **not** exist (no CI in repo — verified 2026-07-10); `FE/test/` **does** exist with a real suite (blocs/models/services/widgets tests, incl. `manager_product_variants_table_test.dart` covering a Phase 5 companion file) — the plan's `flutter test` gates are meaningful, not vacuous.
- Claims checked: 2 | Verified: 2 | Failed: 0 | Unverified: 0

#### Questions & Answers

1. **[Architecture]** Where does the multi-day reskin work live: directly on shared `dev`, or a feature branch?
   - Options: feature branch, merge at closeout (Recommended) | feature branch, merge per-cluster | directly on dev
   - **Answer:** Feature branch `feat/visual-reskin`, merge at Phase 7 closeout by default; per-cluster early merge allowed only for a graded-demo need, with the mixed-palette trade-off recorded.
   - **Rationale:** Team repo with no freeze; `dev` must stay demo-consistent; rollback = don't merge. (Red-team finding 4.)
2. **[Scope]** May Phase 1 add tokens (`onPrimary`, `shadow`, `StatusColors`) to the frozen `docs/design-tokens-v2.md`?
   - Options: additive-only amendment with changelog line (Recommended) | no additions, allowlist everything | re-open the palette
   - **Answer:** Additive-only amendment; approved Warm Terracotta palette values untouched; dated changelog line in the doc.
   - **Rationale:** Zero-hardcode is unreachable without named neutrals (~130 legitimate uses); adding aliases is not a direction change, so it does not violate the user's palette approval.
3. **[Architecture]** `StatusBadge`: cut entirely (as one reviewer urged) or redefine?
   - Options: redefine as OrderStatus-aware DRY consolidation on `StatusColors` (Recommended) | cut entirely | keep original 4-value enum spec
   - **Answer:** Redefine. Original spec was unimplementable (no M3 success/warning slots; 4-value enum vs 5-value OrderStatus); cutting entirely discards real DRY value (4 duplicated `_getStatusColor` maps).
   - **Rationale:** Keeps the audit's component intent, grounds it in verified code reality.
4. **[Risks]** Font delivery: keep google_fonts runtime fetching or bundle?
   - Options: bundle TTFs + `allowRuntimeFetching=false` + offline smoke (Recommended) | runtime fetch + warm-up step
   - **Answer:** Bundle.
   - **Rationale:** Course-demo devices/emulators have unreliable network; silent Roboto fallback is invisible to every QA gate. (Red-team finding 8.)
5. **[Scope]** Orphaned `size_selector.dart`: delete or wire ProductDetail to use it?
   - Options: delete (Recommended) | wire up ProductDetail to import it
   - **Answer:** Delete (grep-verified zero importers at delete time; `flutter analyze` guards).
   - **Rationale:** Wiring up is a behavior-bearing refactor with zero visual gain — out of a visual-only plan's scope; YAGNI.
6. **[Scope]** Motion spec from tokens-v2: implement `AppMotion` now or defer?
   - Options: defer explicitly (Recommended) | add AppMotion tokens in Phase 1
   - **Answer:** Defer, recorded in Out of Scope.
   - **Rationale:** Color/typography/shape is already an 8-phase effort; motion adds QA surface with no demo-grading upside; explicit deferral satisfies the "not silently dropped" criterion.
7. **[Tradeoffs]** Hardcode-guard enforcement point?
   - Options: documented manual pre-PR script (Recommended) | invent GitHub Actions CI | git hook
   - **Answer:** Manual documented script (`FE/scripts/check_hardcoded_colors.sh`), run per cluster phase + Phase 7 closeout. No CI exists in the repo (verified) — inventing one is out of scope; a local git hook is optional developer convenience, not a gate.
   - **Rationale:** Matches the plan's own fallback and the course-project context.
8. **[Assumptions]** Is the plan's `flutter test` gate meaningful?
   - Options: yes, suite verified real (Recommended) | no, downgrade the gate
   - **Answer:** Yes — `FE/test/` contains bloc/model/service/widget tests, including coverage of a Phase 5 companion widget file.
   - **Rationale:** Verified this session; gate stays as written.

#### Confirmed Decisions
- Execution: feature branch + closeout merge + per-phase-boundary re-diff — plan.md Execution Model.
- Tokens: additive-only amendments allowed; palette frozen values untouched.
- StatusBadge: OrderStatus-aware consolidation; `size_selector.dart` deleted; motion deferred; guard = manual script; test gate confirmed meaningful.

#### Action Items
- [x] All eight decisions propagated into plan.md / phase files during Red Team Session 1 application (markers: `<!-- Updated: Red Team Session 1 -->`).

#### Impact on Phases
- Phase 0: branch creation + human-tap triage + stale-ID re-verification. Phase 1: additive tokens, font bundling, chipTheme, widget alias cleanup, guard rewrite. Phase 2: retargeted (orphan delete, product_card 4+5 sites, StatusBadge redefinition). Phases 3-6: live-guard checklists, two-commit rule, stale-ID handling, scope-leak removals. Phase 7: ranking fix, kDebugMode pin, credential rotation, allowlist-aware closeout.

### Whole-Plan Consistency Sweep (Validation Session 1)
- Files reread: plan.md + all 8 phase files; grep sweep over the plan dir for superseded terms.
- Decision deltas checked: 8 (validation answers — all coincide with red-team applications).
- Reconciled stale references: 0 new (3 already fixed in the red-team sweep).
- Unresolved contradictions: **0**.
