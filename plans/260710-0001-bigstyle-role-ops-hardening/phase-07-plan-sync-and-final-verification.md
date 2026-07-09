---
phase: 7
title: "Plan Sync And Final Verification"
status: pending
priority: P1
effort: "0.75d"
dependencies: [1, 2, 3, 4, 5, 6]
---

# Phase 7: Plan Sync And Final Verification

## Overview

Run final verification, reconcile stale plan checklists, and produce a concise PM
completion report. This phase turns implementation evidence into trustworthy
project state.

## Requirements

- Functional: update relevant plan statuses/checklists based on evidence.
- Functional: do not mark ambiguous old checklist items complete.
- Functional: produce final smoke/PM report.
- Non-functional: final branch is clean and ready for PR.

## Architecture

Plan state sources:

- New plan files under `plans/260710-0001-bigstyle-role-ops-hardening/`.
- Old pending demo roadmap:
  `plans/260703-1750-bigstyle-demo-fix-roadmap/plan.md`.
- Partial stability plan:
  `plans/260709-2030-bigstyle-stability-hardening/plan.md`.
- Completed remote-data plan:
  `plans/260709-2231-bigstyle-remote-data-testability-hardening/plan.md`.

Evidence sources:

- Git commits from each phase.
- Flutter analyzer/test output.
- Admin/manager/customer smoke reports.
- Supabase migration/function deploy verification notes.

## File Inventory

| Path | Action | Test impact |
|---|---|---|
| `plans/260710-0001-bigstyle-role-ops-hardening/plan.md` | Modify via `ck plan check` where possible | Mark phase completion. |
| `plans/260710-0001-bigstyle-role-ops-hardening/phase-*.md` | Modify checkboxes/status | Sync phase evidence. |
| `plans/260703-1750-bigstyle-demo-fix-roadmap/plan.md` | Modify cautiously | Reconcile stale demo checklist. |
| `plans/260709-2030-bigstyle-stability-hardening/plan.md` | Modify cautiously | Close or note partial items. |
| `plans/260710-0001-bigstyle-role-ops-hardening/reports/*.md` | Create | Final PM/smoke reports. |

## Tests Before

- Run `ck plan status` on new plan.
- Run `ck plan status` on old pending/partial plans.
- Capture current checkbox counts before edits.

## Implementation Steps

1. Run final `flutter analyze`.
2. Run final `flutter test`.
3. Run optional `flutter test --coverage` and record coverage.
4. Run admin smoke:
   - admin login
   - dashboard
   - users
   - categories
   - invite function with disposable user or approved skip
5. Run manager smoke:
   - dashboard revenue sanity
   - product edit still opens
   - orders tab/status sheet still works
6. Run customer smoke:
   - cart -> checkout -> COD or SePay test path -> orders.
7. Reconcile new plan phases with `ck plan check` if CLI supports it.
8. Sweep old plans and only check items with direct evidence.
9. Write final report:
   `reports/pm-role-ops-hardening-completion.md`.
10. Commit plan/report state separately from code if needed.

## Test Scenario Matrix

| Scenario | Priority | Expected |
|---|---|---|
| Analyzer/test suite | Critical | Pass. |
| Admin smoke | Critical | All admin tabs verified. |
| Admin invite | Critical | Edge Function used; non-admin blocked. |
| Manager revenue | Critical | Matches accepted-status rule. |
| Customer checkout | High | No regression from modularization. |
| Plan sync | High | No false completed checkboxes. |

## Refactor

No code refactor in this phase unless a verification failure requires a small
fix. If a failure is non-trivial, create a follow-up phase or stop and report.

## Tests After

- Repeat failed subset after any fix.
- Re-run `git diff --check`.

## Regression Gate

```bash
git diff --check
cd FE
flutter analyze
flutter test
```

## Success Criteria

- [ ] New plan phase checkboxes/statuses reflect actual completed work.
- [ ] Old pending/partial plan statuses reconciled with evidence.
- [ ] Final PM report exists.
- [ ] Admin, manager, and customer smoke results documented.
- [ ] `git status` is clean after commit.

## Risk Assessment

- Risk: stale plans claim work done without evidence. Mitigation: evidence-first
  mapping; leave ambiguous items unchecked.
- Risk: final smoke mutates demo data. Mitigation: use disposable entities or
  rollback/test accounts.

## Security Considerations

- Reports must not include passwords, JWTs, service-role keys, or raw `.env`.
- Local screenshots remain ignored unless redacted and explicitly approved.

## Dependency Map

Runs after all implementation/refactor phases. Produces the handoff state for PR
and future sessions.
