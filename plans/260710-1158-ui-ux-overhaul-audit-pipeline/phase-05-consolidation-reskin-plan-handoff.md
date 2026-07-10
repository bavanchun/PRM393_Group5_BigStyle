---
phase: 5
title: "Consolidation & Reskin Plan Handoff"
status: completed
effort: "M (1 day)"
priority: P1
dependencies: [4]
---

# Phase 5: Consolidation & Reskin Plan Handoff

## Overview

Stress-test the reskin approach with an adversarial persona debate, then author the actual **big reskin implementation plan** (a new, separate plan dir) fed by every artifact this pipeline produced. This plan's deliverable is that plan — implementation itself stays out of scope.

## Requirements

- Functional: `ck:predict` debate on the proposed migration strategy; a new implementation plan created via `/ck:plan` with phases derived from Phase 4 migration clusters.
- Non-functional: whole-pipeline consistency sweep — no contradictions between tokens v2, gap audit, and the new plan.

## Implementation Steps

1. Consolidate: 1-page executive summary in `reports/phase-05-overhaul-audit-executive-summary.md` (chosen direction, total effort by cluster, top risks, disposition of the 10 `consistency` + 6 `ui` old-audit findings — a checklist, most pre-closed or absorbed trivially by token swap; do not oversell this as substantive inheritance). No PII; accounts by role alias (plan.md hygiene policy).
2. Run `ck:predict` on the proposed reskin strategy (input: executive summary + tokens v2 + gap audit). Focus personas on: regression risk across ~35 screens, performance (google_fonts/rebuild cost), a11y, demo-deadline pragmatism, maintainability of new component layer.
3. Resolve or explicitly accept each blocking objection; append decisions to the executive summary.
4. Author reskin plan via `/ck:plan` (new dir, e.g. `plans/{ts}-bigstyle-visual-reskin-implementation/`). Required phase skeleton (adjust per audit facts):
   - tokens v2 in code (`app_colors/typography/spacing/theme` rewrite) + hardcode-guard gate (grep/lint CI check banning new `Colors.*`/`0xFF` outside theme)
   - shared component layer (target inventory from Phase 4)
   - screen-cluster migrations (one phase per cluster, ordered by demo visibility: customer-shop → checkout → customer-account (incl. delivery-map) → manager → admin → auth/guest)
   - QA net: `ck:scenario`-derived regression checklist per cluster + `flutter analyze`/`flutter test` gates
5. Wire cross-plan metadata: new plan notes it absorbs demo-fix-roadmap's deferred cosmetic backlog; link brainstorm report, tokens v2, gap audit; **state the audited SHA** (from the Phase 2 capture log) and require the reskin plan's first phase to diff current `dev` against it — file:line refs and any recaptured screens get refreshed before implementation starts.
6. Mark this pipeline plan completed (`ck plan check 5` after 1–4 done).

## Success Criteria

- [x] Executive summary written (`reports/phase-05-overhaul-audit-executive-summary.md`); 5-persona predict-style debate run, all 5 objections resolved/accepted with mitigation, none silently dropped, brand direction itself not reopened (locked gate respected).
- [x] Reskin implementation plan exists: `plans/260710-1342-bigstyle-visual-reskin-implementation/` — 8 phases (0 pre-flight, 1 tokens-in-code, 2 shared components, 3-6 the 4 migration clusters split by role, 7 auth/guest) matching Phase 4's clusters + effort tags exactly.
- [x] Reskin plan includes the hardcode-guard gate (Phase 1 of new plan, grep-based script) and a per-cluster regression checklist + `flutter analyze`/`flutter test` gate in every migration phase.
- [x] Cross-links complete: new plan's `plan.md` links brainstorm report, `docs/design-tokens-v2.md`, Phase 4 gap audit; states pinned SHA `6e77ccf...` and requires a re-diff before implementation; notes it absorbs the demo-fix-roadmap's deferred cosmetic backlog (with `.withOpacity` correctly marked already-done, not carried forward as open work).

## Risk Assessment

- **Predict debate reopens the brand direction** → direction is a locked user decision (Phase 3 gate); personas may challenge execution, not the user's identity choice — reversal requires new evidence per review rules.
- **Reskin plan scope balloons** (flow changes sneak in) → hard constraint from user: visual-only, flow unchanged; reject cluster phases that touch navigation.
- **Course deadline pressure** → cluster ordering is demo-visibility-first so partial completion still upgrades what the graders see.
