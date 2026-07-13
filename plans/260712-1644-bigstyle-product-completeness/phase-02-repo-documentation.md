---
phase: 2
title: "Repo Documentation"
status: done
effort: "small"
---

# Phase 2: Repo Documentation

## Overview

Make the repo self-explanatory: rewrite broken README (UTF-16 corrupt, 1 line),
add consolidated architecture doc, relocate legacy plan dirs, sync stale plan
checkboxes. Docs only — no app code.

## Requirements

- Functional: fresh clone can run the app following README alone.
- Non-functional: README UTF-8; `docs/system-architecture.md` ≤800 lines; no secrets/env values in docs.

## Related Code Files

- Rewrite: `README.md` (root)
- Create: `docs/system-architecture.md`
- Move: `FE/plans/*` (2 legacy dirs: auth-otp-google-fix, sepay-payment) → `plans/` (keep dir names, prefix nothing)
- Modify (checkbox sync-back): phase files of ~6 completed plans flagged in PM report `plans/reports/pm-260712-1635-project-status-overview-report.md`

## Implementation Steps

1. Rewrite `README.md` (UTF-8): app description (BigStyle big-size fashion e-commerce, PRM393 Group5), feature list per role (Customer/Manager/Admin), screenshots section (placeholder table if none captured yet), architecture summary linking `CODEBASE.md` + `docs/system-architecture.md`, setup (Flutter version, `FE/.env` keys listed by NAME only, Supabase project note), run instructions (`flutter pub get`, `flutter run`), test instructions, team/group section.
2. Write `docs/system-architecture.md`: FE structure (blocs/screens/services/widgets map), Supabase schema overview (tables, RLS posture, triggers, edge functions), key flows (auth roles, checkout money path, chat realtime, review gate), source: `CODEBASE.md` + `docs/ux-flow-audit.md` + migration history — verify claims against code, don't copy stale statements.
3. `git mv FE/plans/<dir> plans/` for both legacy dirs; check their plan.md status frontmatter reflects reality (likely completed).
4. Checkbox sync-back pass on the ~6 completed plans with unticked boxes (role-based-ux-audit, manager-category-mgmt, app-feature-gap-closure, remote-data-testability, visual-reskin, post-audit-ui-ux-batches): tick items verifiably done (git history/code), leave honest gaps unticked with note.
5. Verify README renders on GitHub (markdown lint pass, no encoding artifacts).

## Success Criteria

- [x] README UTF-8, renders correctly, covers description/setup/run/test/team
- [x] `docs/system-architecture.md` exists, claims match code (code-reviewer pass: 3 findings fixed — theme tokens, model count, pricing-source wording)
- [x] `FE/plans/` removed; 2 dirs live under `plans/`
- [x] Stale checkboxes synced or annotated (159 ticked, 53 honestly annotated across 6 plans — see `plans/reports/from-sync-agent-260712-1713-stale-checkbox-syncback-report.md`)
- [x] No secrets/env values committed (code-reviewer grep pass: 0 matches)

## Risk Assessment

- Sync-back may over-tick — only tick with evidence (commit/code), else annotate.
- CODEBASE.md may be stale in spots → verify each architecture claim before restating.
