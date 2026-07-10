---
title: "BigStyle UI/UX Overhaul — Audit & Direction Pipeline"
description: "Audit-only pipeline preparing the full visual reskin of BigStyle (Flutter + Supabase, 3 roles + guest, ~35 screens): inventory → brand direction (AI-proposed, user-approved) → screenshot capture → per-screen gap audit → consolidation + handoff to the big reskin implementation plan."
status: completed
priority: P1
branch: "dev"
tags: [ui-ux, audit, design-system, reskin, flutter]
blockedBy: []
blocks: []
created: "2026-07-10T05:06:30.279Z"
createdBy: "ck:plan"
source: skill
---

# BigStyle UI/UX Overhaul — Audit & Direction Pipeline

## Overview

**Goal:** produce everything needed to author a high-quality "big reskin plan" — NOT implement the reskin itself. This plan is **audit + design-direction only**; the only repo artifacts it produces are docs/reports (no Dart code changes).

**Locked user decisions** (from brainstorm, 2026-07-10 — see [brainstorm report](../reports/brainstorm-260710-1158-ui-ux-overhaul-skill-pipeline-report.md)):

- **Scope:** full visual reskin, **flow/navigation unchanged** (flows stabilized across 10 prior plans).
- **Brand:** AI proposes 2–3 new identity directions; user approves 1. Current: pink `#C4517A` on `#FDF8F9`.
- **Coverage:** the entire UI surface. Corrected role model (red team): **3 roles + guest** — customer, manager, admin, plus guest (splash/login/OTP). There is NO delivery role (`FE/lib/models/user_model.dart:4` — `enum UserRole { customer, manager, admin }`); `delivery_map_screen.dart` is a customer-profile screen (`profile_screen.dart:128`).
- **Method:** visual (emulator screenshots) + code audit — "kỹ nhất".
- **Order:** direction-first → audit becomes gap-analysis against the approved target (chosen over status-quo-first audit to avoid re-producing generic findings).

**Key context:**

- Stack: Flutter (BLoC) + Supabase. Theme in `FE/lib/config/theme/` (301 lines: colors, spacing, typography, theme).
- ~208 hardcoded `Colors.*`/`0xFF` hits bypass tokens in `lib/screens` + `lib/widgets` (recount at Phase 1 is authoritative; manager dir alone holds ~78). Only 10 shared widgets.
- **Screen counts are NOT the dart-file counts.** 47 dart files under `FE/lib/screens/`, but many are widgets/sheets (manager: 8 of 17 files are non-screens) and at least one screen is a private inline class (`_AdminProfileScreen`, `admin_shell.dart:83`). True screen count ≈ 35; Phase 1 defines "screen" and produces the authoritative number.
- Prior audit `docs/ux-flow-audit.md` (2026-07-03, 111 findings) is the **flow/bug** baseline. Overlap with this pipeline is small and bounded: only 10 findings typed `consistency` + 6 `ui`, several already fixed — cross-referencing them is a checklist item in Phase 4, not a headline workstream.

## Phases

| Phase | Name | Status |
|-------|------|--------|
| 1 | [Inventory & Debt Map](./phase-01-inventory-debt-map.md) | Completed |
| 2 | [Visual Capture 3 Roles + Guest](./phase-02-visual-capture-4-roles.md) | Completed |
| 3 | [Brand Direction & Tokens v2](./phase-03-brand-direction-tokens-v2.md) | Completed |
| 4 | [Screen Gap Audit](./phase-04-screen-gap-audit.md) | Completed |
| 5 | [Consolidation & Reskin Plan Handoff](./phase-05-consolidation-reskin-plan-handoff.md) | Completed |

## Dependency Chain

```
Phase 1 (inventory + entry gates) ──> Phase 2 (capture checklist + verified accounts + Gemini preflight)
Phase 1 ──> Phase 3 (direction proposals need current-state facts)
Phase 3 (tokens v2 approved — USER GATE) ──> Phase 4 (gap audit grades against tokens v2)
Phase 2 (screenshots) ──────────────────────> Phase 4
Phase 4 ──> Phase 5 (consolidate + predict + author reskin plan)
```

Phases 2 and 3 have no data dependency on each other, but **both are gated on the same single user** (OTP logins in 2, direction review in 3) — they are *interleaved single-user work, not parallel*. Recommended order: kick off Phase 3 generation, run Phase 2 capture sessions while direction candidates are being prepared, review directions between capture sessions. Budget 4–6 days total, not 4.

## External Data & Report Hygiene Policy (applies to ALL phases)

Real customer PII (name, email, phone, address) exists in the live app and real account emails are already committed in prior plan reports — this pipeline must not widen that exposure.

1. **Screenshots containing PII** (profile, address/checkout, chat, orders, any screen showing account email/name): validated decision — ALL customer-role screens are captured from the seeded demo customer (fake "Khách Demo" data). If a frame with real personal data slips through anyway, it MUST be redacted (blur/crop) before leaving the machine.
2. **External AI services** (Gemini via `ck:ai-multimodal`, `ck:stitch`, `ck:ai-artist`, and any fallback model): allowed inputs = rubric text, token tables, redacted/dummy-account screenshots, synthetic mocks. Forbidden inputs = any unredacted screenshot showing real personal data. The Phase 4 fallback path inherits this gate unchanged.
3. **Committed reports/docs** (`reports/*.md`, `docs/*.md` — these ARE tracked): must not contain account emails, phone numbers, addresses, OTP codes, or verbatim on-screen personal text. Refer to accounts by role alias only (`customer-A`, `manager`, `admin`).
4. **Asset directory:** `docs/audit-assets/` stays gitignored (`.gitignore:6`). `git add -f` on it is forbidden, including "temporarily for review". If evidence must be shared, produce a redacted subset outside the repo; `file:line` citations are the primary verifiable evidence, screenshot refs secondary.
5. Pre-existing exposure (real Gmail addresses in committed reports of prior plans) is out of this plan's scope but flagged to the team lead for separate cleanup.

## Skill Routing (per phase)

| Phase | Skills |
|---|---|
| 1 | `ck:scout` / Grep-Glob direct + Gemini key preflight |
| 2 | emulator + `adb -s <serial> exec-out screencap` (no browser skills — mobile) |
| 3 | `ck:design` + `ck:ui-ux-pro-max` (Flutter-aware); optional `ck:stitch`/`ck:ai-artist` for concept boards (policy above applies) |
| 4 | `ck:ai-multimodal` (Gemini vision on screenshots) + `ck:ui-ux-pro-max` (design-system review) |
| 5 | `ck:predict` (5-persona debate) → `ck:plan` (author reskin plan) |

**Known trap (from brainstorm):** `frontend-design`, `ui-styling`, `web-design-guidelines`, `react-best-practices` are web-first — do NOT route Flutter audit work to them. `ck:stitch` output (Tailwind/HTML) is visual reference only.

## Cross-Plan Dependencies

None blocking, with one corrected caveat: `260703-1750-bigstyle-demo-fix-roadmap` (partial) previously claimed to deliver the seeded manager account, but its Phase 1 is **in-progress with "manager OTP login not done"** — this pipeline does NOT assume that output exists; account verification is a Phase 1 exit gate here. The demo-fix plan's deferred cosmetic backlog (token cleanup, `Colors.*` hardcode, `.withOpacity`) will be **absorbed by the future reskin plan** authored in Phase 5 — note this in that plan's overview when created.

## Acceptance Criteria (whole plan)

- [x] Phase 1 defines "screen" and produces the authoritative screen list (route destinations + shell tabs + inline screens) with per-file hardcode-debt counts. — `reports/phase-01-ui-inventory-debt-map.md`: 30 screens, 195 hardcode-hit lines recounted.
- [x] Entry gates verified before capture: manager + admin logins proven on the capture AVD; `GEMINI_API_KEY` present and one test call succeeds. — Phase 1 report's Entry Gates section; all 4 gates green via existing evidence + 1 live Gemini analyze call this session.
- [x] Screenshot set covers every inventoried screen for customer, manager, admin, and guest (key states where reachable), stored under `docs/audit-assets/overhaul/` (gitignored), with the capture-time `git rev-parse HEAD` recorded. — `reports/phase-02-visual-capture-log.md`: 26/30 (87%), SHA `6e77ccf...` pinned, 4 unreachable logged with reason (not silently dropped).
- [x] 2–3 brand directions presented; exactly 1 approved by user; `docs/design-tokens-v2.md` spec written with version stamp; final palette re-passes WCAG AA before freeze. — 3 directions presented via `AskUserQuestion`, "Warm Terracotta" approved, `rubric-v1` stamped, all primary text/surface/button pairs computed AA-pass before presentation.
- [x] Gap audit covers 100% of captured screens; every finding has screen ref, token/component mapping, and effort tag (S/M/L); findings persisted per-batch (append-only), not only at phase end. — `reports/phase-04-screen-gap-audit-by-role.md` + 4 per-role checkpoint files; ~150 findings, all `rubric-v1`-mapped, effort-tagged.
- [x] Old audit's 10 `consistency` + 6 `ui` findings dispositioned (absorbed / already-fixed / out-of-scope) — checklist-scale item. — 16/16 dispositioned in Phase 4 report (5 already-fixed, 6 absorbed, 5 still-open-outside-scope), 0 orphaned.
- [x] No PII in any committed report; no asset force-added to git (policy above). — all reports use role aliases only; `docs/audit-assets/` confirmed gitignored throughout, never force-added.
- [x] `ck:predict` debate run on the reskin approach; blocking objections resolved or documented. — `reports/phase-05-overhaul-audit-executive-summary.md`: 5-persona debate, all 5 objections resolved/accepted, none blocking.
- [x] Big reskin implementation plan created (separate plan dir) linking all artifacts and pinned to the audited SHA. — `plans/260710-1342-bigstyle-visual-reskin-implementation/` (8 phases), cross-linked to brainstorm/tokens-v2/gap-audit, pinned to `6e77ccf...` with a mandatory Phase 0 re-diff.

## Out of Scope

- Any Dart/code changes (including token refactors) — belongs to the reskin plan.
- Flow/navigation redesign (user decision: keep flow).
- Re-auditing flow/function bugs (owned by `docs/ux-flow-audit.md` + demo-fix roadmap).
- Cleanup of pre-existing committed PII (flagged, handled separately).

## Validation Log

### Session 1 — 2026-07-10 (4 questions, post-red-team)

| # | Topic | Decision |
|---|-------|----------|
| 1 | Gemini key | **Provided & verified 2026-07-10** (HTTP 200 on models endpoint); stored in local `~/.zshenv` as `GEMINI_API_KEY` — never in repo. Vision models: `gemini-2.5-flash` for batch grading, `gemini-2.5-pro` for ambiguous screens. Phase 1 preflight = confirm one real analyze call |
| 2 | PII capture strategy | **All customer-role screens captured from the seeded demo customer** (fake "Khách Demo" data) — real customer session is NOT the capture vehicle; `needs-redaction` tagging remains only as an exception safety net |
| 3 | Dev freeze | **No freeze possible** (team repo, others merge freely) → rely fully on pinned SHA + delta-recapture rule; drop the soft-freeze request |
| 4 | Timeline | **≥2 weeks available** — full scope (3 roles + guest) unchanged, 4-6 day estimate accepted |

### Verification Results
Skipped per guard: `## Red Team Review` (same session) already contains evidence-backed verification — 44 claims checked across 3 reviewers (Fact Checker 16/16 verified; Assumption/Scope 9 verified, 4 failed → fixed as findings 1/2/7/8; Flow Tracer traced auth/session paths). No `[UNVERIFIED]` tags remain.

### Whole-Plan Consistency Sweep
- Files reread: plan.md, phase-01…phase-05 after validation propagation
- Decision deltas checked: 4 (demo-account capture, no-freeze, Gemini key owner, timeline)
- Reconciled stale references: "real customer session" as capture vehicle (phase-02), soft-freeze request (phase-02 step 0 + risk), PII policy wording (plan.md)
- Unresolved contradictions: 0

## Red Team Review

### Session — 2026-07-10
**Findings:** 13 after dedupe from 21 raw (3 hostile reviewers: Security Adversary, Assumption Destroyer, Failure Mode Analyst) — 13 accepted, 0 rejected.
**Severity breakdown:** 2 Critical (factual), 4 High, 7 Medium.

| # | Finding | Severity | Disposition | Applied To |
|---|---------|----------|-------------|------------|
| 1 | "Delivery" is not a role — app has 3 roles; delivery-map is a customer screen | Critical | Accept | plan.md, Phases 1/2/4/5 |
| 2 | Manager account NOT seeded (demo-fix Phase 1 in-progress); admin login path unresolved | Critical | Accept | plan.md, Phases 1/2 |
| 3 | Real-customer PII shipped to Gemini free-tier with no redaction; multi-vendor data policy missing | High | Accept | plan.md policy, Phases 2/4 |
| 4 | Committed reports lack PII-hygiene rule; capture log would extend committed identity trail | High | Accept | plan.md policy, Phases 2/4/5 |
| 5 | Session-loss model wrong: every role switch = OTP cycle; existing debug dart-define password login ignored; OTP rate limits unbudgeted | High | Accept | Phase 2 |
| 6 | No commit-SHA pinning — pipeline reproduces the staleness failure it condemns (dev is hot) | High | Accept | Phases 2/4/5 |
| 7 | Screen counts are file counts (~35% inflated); inline screens invisible to file-count method | Medium | Accept | plan.md, Phase 1 |
| 8 | Route table holds only 19 routes — router-first inventory method cannot enumerate shell-hosted screens | Medium | Accept | Phase 1 |
| 9 | `GEMINI_API_KEY` not configured; no preflight before ~2 days of work funnels into Phase 4 | Medium | Accept | Phases 1/4 |
| 10 | `pm clear`/second-AVD "alternatives" destroy the session / contradict same-AVD requirement; `adb -s` unspecified | Medium | Accept | Phase 2 |
| 11 | Phase 3 merge path bypasses WCAG re-check; rubric unversioned; re-grade cost unbounded | Medium | Accept | Phases 3/4 |
| 12 | Phase 4 has no mid-phase checkpointing — single end-of-phase artifact for 1.5–2 days of grading | Medium | Accept | Phase 4 |
| 13 | "Phases 2 ∥ 3" false — both gated on the same single user; consistency-absorb workstream overstated (≤6 open items) | Medium | Accept | plan.md, Phases 4/5 |

### Whole-Plan Consistency Sweep
- Files reread: plan.md, phase-01…phase-05 (all rewritten/edited this session)
- Decision deltas checked: 13 (role model, account gates, PII policy, debug login, SHA pin, screen definition, inventory method, Gemini preflight, capture mitigations, WCAG/rubric versioning, checkpointing, parallelism wording, consistency-absorb scale)
- Reconciled stale references: "4 roles/delivery" in title-adjacent text, "44 screens" math, "seeded by demo-fix" claim, "2∥3 parallel" claim, `pm clear` alternative, "admin+delivery" cluster
- Unresolved contradictions: 0. Note: phase-02 filename keeps historical slug `visual-capture-4-roles` (CLI-generated); content and phase title corrected to "3 Roles + Guest" — cosmetic only.
