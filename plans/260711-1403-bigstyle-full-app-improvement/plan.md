---
title: "BigStyle Full-App Improvement (fixes + hardening + verification)"
description: ""
status: pending
priority: P2
branch: "dev"
tags: []
blockedBy: []
blocks: []
created: "2026-07-11T07:04:57.223Z"
createdBy: "ck:plan"
source: skill
---

# BigStyle Full-App Improvement (fixes + hardening + verification)

## Overview

Fix + harden + verify BigStyle from the 2026-07-11 test pass. Groups: A correctness/money (F1 voucher, F5 dashboard, F3 enum), B data integrity (F2 stock, F4 shipping), C security/perf DB hygiene, D data cleanup, E verification harness. TDD per phase; all DB migrations go through a **Supabase branch** (test → merge), never straight to prod (`agbnpqgxsppdrpbqoipo`, real data). Cook executed separately (Sonnet 5).

Source: [brainstorm direction](../reports/brainstorm-260711-1403-bigstyle-full-app-improvement-big-plan-direction-report.md) · [test report](../reports/qa-260711-1220-bigstyle-full-app-test-automated-backend-report.md) · [scout](../reports/scout-260711-1208-bigstyle-full-app-architecture-map-report.md).

## Phases (post red-team restructure)

> Red-team (4 hostile reviewers, 2026-07-11) restructured this plan — see `## Red Team Review`. Phases **1+2+5 merged** into one `create_order` money-path phase (they rewrite the same function → separate merges would clobber each other). Old phase files `phase-02-*` and `phase-05-*` are now **pointers** to phase-01. Phase 7 **cut** to its safe subset (consolidation deferred). Phase 9 kept but marked **non-blocking / separable**.

| Phase (file) | Name | Group | Sev | Deps | Status |
|-------|------|-------|-----|------|--------|
| 01 | [create_order money-path hardening (voucher + stock + shipping)](./phase-01-voucher-discount-apply.md) | A+B | HIGH | repatriate vouchers/validate_voucher DDL first | Pending |
| 03 | [Order-status enum alignment (Dart model bug)](./phase-03-order-status-enum-alignment.md) | A | MED | — | Pending |
| 04 | [Manager dashboard customer count (RLS/data, not query)](./phase-04-manager-dashboard-customer-count.md) | A | MED | — | Pending |
| 06 | [Security hygiene DB](./phase-06-security-hygiene-db.md) | C | MED | — | Pending |
| 07 | [RLS perf hygiene — SAFE subset (wrap + FK index only)](./phase-07-rls-perf-hygiene.md) | C | LOW | — | Pending |
| 08 | [Data cleanup pricing](./phase-08-data-cleanup-pricing.md) | D | LOW | — | Pending |
| 09 | [Verification harness native + zero-row (non-blocking)](./phase-09-verification-harness-native-and-zero-row.md) | E | KVM enabled | Pending |
| — | ~~phase-02 stock~~ → merged into 01 | — | — | — | Merged |
| — | ~~phase-05 shipping~~ → merged into 01 | — | — | — | Merged |

Merged Phase 01 is one serialized migration on one Supabase branch (voucher → stock → shipping in one `create_order` body) + a paired down-migration. Phases 03/04/06/07/08 independent. Phase 09 does NOT block plan completion (plan is "done" at 01+03+04+06+07+08); it runs as a separate KVM-gated verification track and may spawn its own fix plans.

## Acceptance criteria (whole plan)
- [ ] Valid voucher reduces `orders.total` by the exact server-validated discount (F1).
- [ ] Oversell attempt is rejected; `stock_qty` decrements on success (F2).
- [ ] `processing`/`refunded` orders render their true label, not "Chờ xác nhận" (F3).
- [ ] Manager dashboard "Khách hàng" shows the real customer count (F5).
- [ ] `shipping_fee` derived/validated server-side, not trusted from client (F4).
- [ ] Addressed Supabase security + perf advisor warnings cleared.
- [ ] Catalog prices realistic (no uniform 10.000đ) (D).
- [ ] `flutter analyze` 0, full `flutter test` green incl. new regression tests.
- [ ] (E) each of reviews/wishlist/chat/support has ≥1 real e2e row; native flows demonstrated on emulator.

## Cross-cutting constraints
- **DB via Supabase branch only.** `create_branch` → apply migration → test → `merge_branch`. Keep every migration idempotent. Snapshot/verify before merge.
- **TDD.** Each phase writes failing tests first (lock current behavior / assert new), keep existing 104 tests green.
- **Preserve server-authoritative pricing** in `create_order` (already verified working) while adding voucher/stock/shipping logic.
- No plan-id/phase-number in code comments, commit messages, or test names (explain behavior directly).

## Dependencies
- Cross-plan: [`260703-1750-bigstyle-demo-fix-roadmap`](../260703-1750-bigstyle-demo-fix-roadmap/plan.md) (partial) raised a manager-dashboard customer-count concern that **Phase 4 (F5) supersedes** — reconcile/close there after Phase 4. [`260710-2235-review-gate-map-chat-hardening`](../260710-2235-review-gate-map-chat-hardening/plan.md) (in-progress) touches map/chat which **Phase 9** verifies — coordinate so Phase 9 runs after it settles.

## Open questions — RESOLVED by validation interview (2026-07-11)
- **F3:** managers do NOT set `processing`/`refunded` — read-only render, `isCancellable=false`, not in manager `nextStatuses` (those states come from webhook/admin/SQL). → Phase 03.
- **F4:** shipping flat **30.000đ** (`app_config.dart:22`); server override in Phase 01. Distance-based out of scope.
- **Voucher redemption:** ENFORCE — vouchers have a usage limit; Phase 01 adds redemption tracking (`voucher_redemptions` table or `used_count`/`usage_limit`) + atomic guard in `create_order`. Not unlimited public codes.
- **D price source:** reuse the varied prices captured in existing `order_items` as the reference for realistic catalog prices → Phase 08.
- **Supabase branch origin:** repatriate `vouchers` + `validate_voucher` DDL into repo migrations FIRST, then build the branch from repo migrations (faithful + reproducible) → Phase 01 prereq.

## Validation Log
Interview (2026-07-11, Opus 4.8) — 4 critical questions, all resolved. Verification pass skipped (Red Team Review already provides codebase-verified evidence; no `[UNVERIFIED]` tags).

| # | Decision | Affects | Propagated |
|---|----------|---------|-----------|
| V1 | Vouchers ARE limited → enforce redemption (usage_limit/per-user + atomic guard) | Phase 01 | ✓ (adds redemption schema + logic; not just "document unlimited") |
| V2 | `processing`/`refunded` read-only, NOT manager-settable | Phase 03 | ✓ (renderable read-only, isCancellable=false, excluded from manager nextStatuses) |
| V3 | Realistic prices derived from existing `order_items` captured prices | Phase 08 | ✓ (source = order_items, not curated/user-supplied) |
| V4 | Repatriate voucher DDL → branch from repo migrations | Phase 01 | ✓ (confirms RT-1 prereq; branch is faithful) |

### Whole-Plan Consistency Sweep (post-validation)
- Phase 01: RT-2 "enforce OR document" → decided **enforce** (V1); redemption tracking is now in scope, not optional. Branch origin (V4) confirms RT-1 repatriate-first path. ✓
- Phase 03: default "read-only" (RT-14) now confirmed as the decision (V2) — no manager transition wiring. ✓
- Phase 08: price source pinned to `order_items` (V3) — resolves the open question. ✓
- No contradictions remain. Plan is implementation-ready; cook applies RT-1..RT-15 + V1..V4.

## Red Team Review
4 hostile reviewers (Security Adversary, Assumption Destroyer, Failure Mode Analyst, Scope Critic), 2026-07-11, Opus 4.8. 15 findings, all evidence-cited (`file:line`), all **Accepted**. Deduped across reviewers. This section is authoritative — cook must honor it over any stale phase prose.

### CRITICAL
- **RT-1 — `validate_voucher` + `vouchers` table are NOT in repo migrations** (only on prod). Real `create_order` source = `FE/supabase/migrations/20260708120000_create_order_rpc.sql:96-98` (the `v_discount := 0` stub), NOT `FE/schema.sql`. → Phase 01 must FIRST repatriate `vouchers` + `validate_voucher` DDL into a baseline migration (dump via `pg_get_functiondef`), pin the exact source file, and verify the real raise/return-0/return-NULL contract before wiring. (3/4 reviewers.)
- **RT-2 — No voucher redemption tracking** (`validate_voucher(p_code,p_subtotal)` has no user/order binding; `voucher_model` has no used_count/usage_limit). After Phase 01 this makes one code infinitely reusable = money exploit. → Phase 01 must enforce redemption atomically OR the "unlimited public code" intent must be an explicit documented decision; plus clamp `0 ≤ discount ≤ subtotal`.
- **RT-3 — Stock decrement without restock-on-cancel = permanent inventory leak.** `cancel_my_order` only sets status; 6 of 7 live orders are cancellable. → Phase 01 must add restock to `cancel_my_order` (and any admin/refund cancel path) in the SAME phase.

### HIGH
- **RT-4 — Discount can swallow shipping / `total = NULL`.** Clamp is on total only; `NULL` discount propagates. → `v_discount := greatest(least(coalesce(v_discount,0), v_subtotal), 0)` before `v_total := v_subtotal + v_shipping - v_discount`.
- **RT-5 — Phase 04 MISDIAGNOSES F5.** `manager_dashboard_stats.dart:35` already counts `role=='customer'` correctly; the real cause is the manager client receives 0 customer rows (RLS: `is_manager()` false / role-value / profiles visibility). Fixing `fromRows` won't fix prod. → Reproduce under the manager JWT, fix the actual layer (RLS/`is_manager()`/seed role), test through RLS not a mock.
- **RT-6 — Phases 1/2/5 layering was self-contradictory** (separate merges vs one shared `create_order` body → last-writer `create or replace` clobbers). → MERGED into one serialized Phase 01 migration + regression test asserting all three invariants (discount applied AND stock decremented AND server shipping) on the final body.
- **RT-7 — Phase 07 had no negative test** — a positive role-smoke can't catch RLS broadening (cross-tenant PII leak in orders/shipping_address). → Cross-tenant DENY assertions are hard success criteria; snapshot `pg_policies` diff pre/post.
- **RT-8 — No rollback for a bad `create_order` migration** on the live money path; in-flight `pending·bank` orders have live payment watches. → Each money-path migration ships a paired down-migration (restore prior full body) + pre-merge check that existing pending/confirmed orders still read/return identically.

### MEDIUM
- **RT-9 — `FE/schema.sql` is a stale "CurveFit" snapshot** (744 lines, wrong project name, lacks `create_order`). → Strike it from ALL phase "Modify" targets; `FE/supabase/migrations/` is the sole DB source of truth; pin exact files.
- **RT-10 — Phase 06 REVOKE list wrongly includes `handle_new_user`** (trigger-only; revoke is no-op or breaks signup if "made to bite") + storage-policy rewrite under-specified (could 403 all catalog/review images). → Drop trigger-only funcs from REVOKE; specify exact storage policy keeping public object GET, remove only listing; add an anonymous URL-fetch check.
- **RT-11 — Phase 07's 120-policy consolidation is over-scoped** for a 7-order demo (max blast radius, zero real benefit). → CUT the consolidation; Phase 07 keeps only the safe `(select auth.uid())` wrap + 7 FK indexes. Defer consolidation to a separate future plan if ever justified by scale.
- **RT-12 — Phase 09 (verification, user-blocked on KVM) shouldn't block a fix plan.** → Kept in-plan per user's "A→E together" choice but marked non-blocking/separable: plan completes at 01+03+04+06+07+08; 09 runs as its own KVM-gated track post-merge.
- **RT-13 — Phase 03 exhaustive `switch(OrderStatus)` with `default:` clauses silently swallow new values** (`flutter analyze` won't warn). → Grep every switch; audit `default:` clauses; keep `orElse` guard but add assert/log so unknowns are visible.
- **RT-14 — Phase 03 over-specifies the transition graph.** → Add `processing`/`refunded` as renderable, read-only, `isCancellable=false`; defer manager-transition wiring to cook once the F3 question is answered.
- **RT-15 — TDD is theater for DB-only Phases 06/07/08** (no Dart surface). → Scope "failing test first" to Phases 01/03/04; for 06/07/08 use `get_advisors` diff + role smoke as the verification gate.

### Cleared (no defect)
Shipping = 30.000đ authoritative (no 40k); 104 tests real; `create_order` single-tx so RAISE rolls back partial inserts (RT confirms Phase 01 tx premise valid).

### Whole-Plan Consistency Sweep
- Phase table updated to 7 active phases (01/03/04/06/07/08/09) + 2 merged pointers. ✓
- `FE/schema.sql` removed as a source target everywhere → `FE/supabase/migrations/` (RT-9). ✓
- Phase 04 reframed from "wrong query" to "RLS/data visibility" (RT-5). ✓
- Phase 07 scope reduced to wrap+indexes; consolidation deferred (RT-11). ✓
- F4 open question resolved (30.000đ); voucher-redemption open question added (RT-2). ✓
- No remaining contradictions. Cook must apply RT-1..RT-15 as it executes each phase.
