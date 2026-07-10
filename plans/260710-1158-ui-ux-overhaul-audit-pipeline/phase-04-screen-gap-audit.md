---
phase: 4
title: "Screen Gap Audit"
status: completed
effort: "L (1.5–2 days)"
priority: P1
dependencies: [2, 3]
---

# Phase 4: Screen Gap Audit

## Overview

Grade every captured screen against the approved tokens-v2 rubric, producing a per-screen gap table where **every finding is directly actionable in the reskin plan** (screen → what deviates → which v2 token/shared component fixes it → effort S/M/L). This is gap-analysis against a target, not open-ended critique — the differentiator from the 2026-07-03 audit.

## Requirements

- Functional: 100% of Phase 2 captured screens graded; findings typed (`color` / `type` / `shape` / `spacing` / `hierarchy` / `a11y` / `component`), each with evidence — **`file:line` is the primary verifiable evidence** (screenshots are gitignored and unreviewable by teammates), screenshot ref secondary. Code refs cite the SHA pinned in the Phase 2 capture log.
- Non-functional: audit-only; findings deduplicated via component-level grouping (a bad button style = 1 component finding + affected-screen list, not N copies); **plan.md External Data & Report Hygiene Policy applies** — frames tagged `needs-redaction` must be redacted (or swapped for demo-account frames) before ANY external API call, the fallback path included; assets never enter git (`git add -f` forbidden); report contains no verbatim on-screen personal text.

## Skill Routing

- `ck:ai-multimodal` (Gemini vision) — batch-analyze screenshots against the rubric: visual hierarchy, contrast, spacing rhythm, touch-target size (≥48dp), density, alignment.
- `ck:ui-ux-pro-max` — design-system review of the 10 shared widgets + theme files at code level; component-inventory gap (which shared components are MISSING and force bespoke UI — e.g. app_chip, app_badge, app_sheet, empty-state, skeleton).

## Implementation Steps

1. Build grading batches by role from Phase 2 capture log (cap ~8-10 images per `ai-multimodal` call); feed rubric from `docs/design-tokens-v2.md` into each call and cite the **rubric version stamp** in every batch. PII gate first: batch only demo-account or redacted frames.
2. Vision pass: per screen, record deviations vs v2 + universal heuristics (contrast AA, touch targets, thumb-zone for primary CTAs, text truncation/VN diacritics clipping). **Checkpoint after every batch:** append findings to a per-role, append-only file (`reports/phase-04-gap-findings-{role}.md`) immediately — a mid-phase failure may lose at most one batch, never the phase.
3. Code pass (`ui-ux-pro-max`): shared widgets vs v2; produce **target component inventory** — the shared-widget set the reskin should end with, mapped from Phase 1 bespoke-UI hotspots.
4. Cross-reference `docs/ux-flow-audit.md` — checklist-scale, not a workstream: only 10 `consistency` + 6 `ui` findings exist and several are already fixed; disposition each as absorbed-by-v2-migration / already-fixed / still-open-outside-scope.
5. Assign effort (S/M/L) per screen using Phase 1 cost tiers × finding count; group findings by proposed migration cluster (auth/guest, customer-shop, customer-account — includes delivery-map, checkout, manager, admin).
6. Consolidate per-role checkpoint files into `reports/phase-04-screen-gap-audit-by-role.md` (per-role tables) + summary matrix (screens × finding types × effort).

## Success Criteria

- [x] Every captured screen (26/30) has a gap entry; 4 unreachable screens got a code-read-inferred entry instead of being silently skipped. Findings persisted per-batch in 4 append-only checkpoint files (`phase-04-gap-findings-{guest,customer,manager,admin}.md`) during the audit, not only in the final report.
- [x] No unredacted PII-bearing frame sent to Gemini — phase-02 log confirmed 0 `needs-redaction` frames; all 26 images sent as-is, no external-call gate triggered.
- [x] Every finding maps to a `rubric-v1` token/component or named universal heuristic — no free-floating notes. One reliability caveat added: cited contrast-ratio *numbers* were spot-checked and found inconsistent/hallucinated (four different values for the same color pair); the underlying "check this" flags are kept, the specific numbers are marked unverified.
- [x] Target component inventory written: 8/10 shared widgets keep (token-swap only), 2/10 rework (`size_selector.dart`, `product_card.dart` — both code-confirmed, not just visual), 1 new component identified (`StatusBadge`, tonal — highest leverage, closes 13 findings).
- [x] Old-audit cross-reference complete: 16/16 dispositioned (5 already-fixed, 6 absorbed-by-v2-migration, 5 still-open-outside-scope), 0 orphaned.
- [x] Effort tags + migration clusters assigned in `phase-04-screen-gap-audit-by-role.md` — directly consumable by Phase 5.

See [phase-04 consolidated report](./reports/phase-04-screen-gap-audit-by-role.md) for full data.

## Risk Assessment

- **Vision-model hallucination** (flagging non-issues) → require every vision finding to cite a visible element; spot-check ~10% against code before accepting.
- **Finding explosion (~35 screens × types)** → component-level dedup rule (step above) is mandatory, not optional; cap per-screen table rows to real deviations.
- **Gemini quota/failure mid-batch** → key was preflighted in Phase 1; per-batch checkpointing bounds loss to one batch; fallback: Claude-native image reading per screenshot (slower — re-estimate remaining effort when switching), **inheriting the same PII/redaction gate**; note tool substitution in report.
- **Rubric change mid-phase** → bounded re-grade rule from tokens v2 (only affected finding types re-checked); rubric version cited per batch makes affected batches identifiable.
