---
title: 'Review gate, order-linked map, human chat & verification pass'
description: >-
  Close review purchase-gate hole (FE+RLS), UI cancel-on-confirmed, defect batch
  D1-D6, order-linked delivery map, manager-customer human chat, final
  emulator+Supabase verification pass
status: in-progress
priority: P1
branch: dev
tags:
  - tdd
  - security
  - feature
  - verification
blockedBy:
  - 260712-1644-bigstyle-product-completeness
blocks:
  - 260703-1750-bigstyle-demo-fix-roadmap
created: '2026-07-10T15:36:31.767Z'
createdBy: 'ck:plan'
source: skill
---

# Review gate, order-linked map, human chat & verification pass

## Overview

From brainstorm `plans/reports/brainstorm-260710-2227-remaining-issues-flows-and-next-updates-report.md`. Mode: `--tdd --deep`. Four workstreams user approved: (1) review purchase-gate (real hole — `schema.sql:390` RLS only checks `auth.uid() = user_id`; any logged-in user reviews any product) + review CTA from delivered orders, (2) cancel-on-confirmed + defects D1–D6, (3) delivery map linked to real order coords (already stored in `shipping_address` jsonb), (4) manager↔customer human chat (Supabase Realtime), (5 → Phase 6) standard email+password sign-in/sign-up (added 2026-07-10 23:03 per user request — test convenience + conventional UX). Phase 5 = single emulator+Supabase runbook clearing this plan's runtime checks **plus** the pre-existing verification backlog (demo-fix-roadmap Phase 1 seed/junk cleanup, stability-hardening smoke, post-audit spot-checks).

**TDD rule (all code phases):** write/extend tests first against current behavior, watch them fail for new behavior, then implement. Test convention = hand-written fakes + DI (see `FE/test/blocs/manager_bloc_test.dart` FakeService pattern, `FE/test/services/admin_service_test.dart` injector pattern) — no mocktail.

**Key facts (verified 2026-07-10, recon):**
- `reviews` table ALREADY has `order_item_id` (FK order_items, set null) + `is_verified` (`FE/schema.sql:371-383`) — unused by app. Gate = populate + enforce, no new columns.
- `OrderModel` already carries `latitude`/`longitude` in `shipping_address` jsonb (`FE/lib/models/order_model.dart:84-85`) — map phase needs no geocoding.
- Migrations canonical dir: `FE/supabase/migrations/` (`YYYYMMDDHHMMSS_description.sql`); `FE/schema.sql` is baseline reference — update both.
- Router = raw string switch in `FE/lib/config/routes/app_router.dart`; blocs registered in `MultiBlocProvider` `FE/lib/main.dart:111-139`.

## Phases

| Phase | Name | Status |
|-------|------|--------|
| 1 | [Review Purchase-Gate & Delivered-Order Review CTA](./phase-01-review-purchase-gate-delivered-order-review-cta.md) | Done (PR #17) |
| 2 | [Cancel-on-Confirmed & Defect Batch D1-D6](./phase-02-cancel-on-confirmed-defect-batch-d1-d6.md) | Done (PR #18) |
| 3 | [Order-Linked Delivery Map](./phase-03-order-linked-delivery-map.md) | Done (PR #19) |
| 4 | [Manager-Customer Human Chat](./phase-04-manager-customer-human-chat.md) | Done (PR #21) |
| 5 | [Emulator & Supabase Verification Pass](./phase-05-emulator-supabase-verification-pass.md) | DB pass done (migrations applied + gate/chat triggers verified live 2026-07-11); device pass pending |
| 6 | [Email-Password Sign-In & Sign-Up](./phase-06-email-password-sign-in-sign-up.md) | Done (PR #20) |

**Execution note (2026-07-11):** Phases 1→2→3→6→4 implemented TDD, each its own PR squash-merged to `dev` (each code-reviewed; findings fixed pre-merge). `flutter analyze` 0, `flutter test` 104 green, hardcode-color guard 0 on `dev`. Migrations written but NOT applied — Phase 5 applies + verifies them live.

Phases 1–4, 6 independent in code (parallel-safe except phases 1, 2 AND 3 all touch `order_detail_screen.dart` — serialize those three on that file). Phase 5 (verification) runs LAST — depends on 1–4 and 6 merged. Recommended execution order: 1 → 2 → 3 → 6 → 4 → 5.

## Acceptance Criteria (plan-level)

- [ ] Non-purchaser cannot submit review (blocked in UI **and** rejected by RLS when bypassing UI).
- [ ] Delivered order detail offers per-item "Đánh giá" CTA opening review editor; submitted review shows `is_verified` badge.
- [ ] Confirmed orders cancellable from UI (`cancel_my_order` first repatriated into repo migrations + verified from source — Phase 2 step 0).
- [ ] D1–D6 defects resolved (see phase 2 table).
- [ ] Order detail of `shipping` order opens map routing shop → order's stored lat/lng.
- [ ] Customer can chat with human manager; manager inbox lists conversations with unread badge; realtime both directions.
- [ ] Standard email+password đăng nhập/đăng ký works alongside OTP + Google; role redirect intact (Phase 6).
- [ ] `flutter analyze` 0 issues; `flutter test` green (baseline = current suite count at execution + new); hardcode-color guard 0.
- [ ] Phase 5 runbook executed: all checklist items ticked incl. demo-fix-roadmap Phase 1 seed items → that plan flips `completed`.

## Dependencies

- **blocks** `260703-1750-bigstyle-demo-fix-roadmap` (partial): its remaining Phase-1 DB/runtime seed items are absorbed into Phase 5 here; roadmap closes when Phase 5 done.
- Supabase project access (migrations, RLS) + Android emulator required for Phase 5; phases 1–4 are code+tests only.

## Red Team Review

### Session — 2026-07-10
**Findings:** 24 raw → 13 deduplicated clusters (13 accepted, 0 rejected)
**Severity breakdown:** 1 Critical, 8 High, 4 Medium
**Reviewers:** Security Adversary, Assumption Destroyer, Failure Mode Analyst (all evidence-backed with file:line)

| # | Finding | Severity | Disposition | Applied To |
|---|---------|----------|-------------|------------|
| 1 | Chat conversation trigger/upsert blocked by RLS (no UPDATE policy) → chat DOA | Critical | Accept | Phase 4 (SECURITY DEFINER trigger + get_or_create RPC, no client upsert) |
| 2 | Participant message-UPDATE policy = content tampering; per-column claim false | High | Accept | Phase 4 (mark_conversation_read RPC, zero UPDATE grants) |
| 3 | `is_verified` spoofable: INSERT-only trigger misses upsert-UPDATE; owner PATCH | High | Accept | Phase 1 (BEFORE INSERT OR UPDATE trigger + immutability guard) |
| 4 | Policy didn't bind `order_item_id` → forged provenance / UUID oracle | High | Accept | Phase 1 (policy binds `oi.id = reviews.order_item_id`) |
| 5 | `cancel_my_order` undefined in repo (live-DB drift); "verified" unfalsifiable | High | Accept | Phase 2 (step 0 repatriation before UI change) |
| 6 | `update_product_rating` invoker-rights → customer review never bumps avg_rating | High | Accept | Phase 1 migration item 4 + Phase 5 check |
| 7 | App-scoped thread bloc → manager conversation-switch race | High | Accept | Phase 4 (screen-scoped bloc + switch test) |
| 8 | Review UPDATE-policy decision deferred → decided now (mirror gate + backfill/prune seed) | High | Accept | Phase 1 items 2,5 + rollback block |
| 9 | Manager nav tile pattern doesn't exist (const bottom nav, no badge) | High | Accept | Phase 4 (bottom-nav tab + unread badge; nav de-const scoped — per Validation decision 2, superseding the dashboard-card suggestion) |
| 10 | Phase 5 adversarial probes too thin for new surfaces | Medium | Accept | Phase 5 section B (tamper/leak probes) |
| 11 | Inbox N+1 + stale unread | Medium | Accept | Phase 4 (denormalized preview/unread via trigger) |
| 12 | Map: 3 `_customerLocation` producers incl. recenter L318; wrong symbol; no coord-bearing seed order; no mock-location step | Medium | Accept | Phase 3 + Phase 5 A4/pre-step 4 |
| 13 | Migration drift (loose sepay file, unguarded publication add); nonexistent test files named "extend"; "66 tests" unanchored | Medium | Accept | Phase 4 guards, Phase 5 pre-step 2, Phase 1 wording, plan.md AC |

### Session — 2026-07-10 (Phase 6 addendum)
**Findings:** 7 (1 Critical, 6 High/Medium), all accepted, folded into phase-06 (see its Red Team Log). Headline: `_onPasswordSignIn` is debug-only (`kReleaseMode` guard → dead login button in release); OTP name-backfill pattern has inverted null-check (full_name never written) → replaced with `handle_new_user` metadata migration; `AuthFailure` doesn't exist (→ `AuthError`); duplicate-email obfuscated-user path; `droppable()` on password handlers.

### Final Audit — 2026-07-10 23:22 (2 auditors: consistency/executability + coverage)
Citations 20/20 accurate; all 13 clusters + F1–F7 + 8 validation decisions confirmed present. Fixed from audit: **B1** Phase-1 trigger self-contradiction (guard vs is_verified setter → merged into ONE trigger, is_verified always recomputed, guard covers provenance columns only); **S1** Phase-5 migration list missing Phase 6; **S2** stale row-9 cell (dashboard card → bottom-nav tab); **S3** stale phase-5 pre-step 1 (env resolved); **S4** false Phase2↔4 collision claim removed + `order_detail_screen.dart` serialization now lists phases 1/2/3; **S5** eligibility `maybeSingle` → `limit(1)` + reuse existing review's order_item_id; **N1** cancel-gate pseudo-code corrected to instance getter; **N2** drift list includes `20260620_wishlist_items.sql`; **N3** single OTP entry control. Zero unresolved contradictions after fixes.

### Whole-Plan Consistency Sweep
Re-read all plan files post-application. Reconciled: "66 tests" → current-suite baseline (plan.md, phase-01); "RPC already permits" → repatriate-then-verify (plan.md AC, phase-02 overview/risk); `_getRoute` → `_calculateRoute` (phase-03); upsert conversation → RPC (phase-04 throughout, success criteria updated); Phase 5 checklist extended to cover all accepted probes. No unresolved contradictions.

## Validation Log — 2026-07-10

User decisions (interview):
1. Seed reviews without delivered order: **backfill or delete** (gate stays strict) → Phase 1 item 5.
2. Manager chat entry: **bottom-nav tab with unread badge** (overrides dashboard-card recommendation; nav de-const scoped) → Phase 4.
3. Phase 5 target env: **current hosted Supabase project** (OTP 60s window; resolves prior open question).
4. Implementation: **single feature branch from `dev`** (e.g. `feat/review-gate-map-chat`), PR to dev after code phases; Phase 5 verifies post-merge.

Phase-6 addendum (2026-07-10 23:05):
5. Login default = **password form**, OTP as secondary link; Google unchanged.
6. Hosted Supabase "Confirm email" → **user will turn OFF** in dashboard (code still handles both paths).
7. Cook mode: **per-phase checkpoints** — implement one phase, report, wait for user OK before next.
8. Cook **deferred to a later session** (user decision 23:10) — this session ends at plan-complete.

## Open Questions

1. Chat conversation assignment: shared manager inbox (any manager replies) chosen — per-manager assignment excluded (YAGNI).
2. Legacy AI-chat `chat_messages` schema mismatch (`role` column vs model's `is_from_ai`, `FE/schema.sql:423-430`) — noted in Phase 4 risk; fix only if AI history persistence proves broken during Phase 5.
