---
phase: 7
title: "RLS perf hygiene"
status: completed
effort: ""
---

# Phase 7: RLS perf hygiene

> ⚠️ **RED-TEAM OVERRIDE — SCOPE CUT (RT-11).** Do ONLY the two SAFE, behavior-preserving parts: (1) wrap `auth.uid()` → `(select auth.uid())` in policies (pure perf), (2) add the 7 FK indexes (additive). **CUT the 120-policy consolidation** — max blast radius (silent RLS broadening = PII leak) for zero real benefit at 7-order scale; defer to a separate future plan only if real scale ever justifies it. IF any consolidation is ever done: a positive role-smoke CANNOT catch broadening (RT-7) — require **cross-tenant DENY** assertions (customer A selecting customer B's orders/order_items/payments/cart returns 0 rows; anon sees only active products) as hard criteria, plus a `pg_policies` pre/post diff. (RT-15) DB-only → verify via advisor diff + role smoke, not Dart TDD. (RT-9) Source = `FE/supabase/migrations/`.

## Overview
Group C-perf (safe subset): wrap bare `auth.uid()` in `(select …)` and add the 7 unindexed-FK indexes. The 120-policy consolidation is CUT per RT-11.

## Requirements
- Wrap `auth.uid()` → `(select auth.uid())` in RLS policies so it's evaluated once per query, not per row.
- Consolidate duplicate permissive policies (same table/role/action) into single policies where semantics allow.
- Add indexes for the 7 unindexed foreign keys.

## Architecture
DB migration on a Supabase branch. This is the highest-risk hygiene phase because policy edits can change access semantics — do it carefully, table by table, re-testing each role's read/write after. The `auth.uid()` wrap is behavior-preserving (pure perf). Policy consolidation must preserve the union of access the duplicates granted. Index additions are safe.

## Related Code Files
- Modify (DB branch migration): RLS policies + `CREATE INDEX` for the 7 FKs. Source: `FE/schema.sql` / migrations.
- Verify: `get_advisors performance` before/after; per-role smoke (customer sees own cart/orders; manager sees all; anon sees only active products).
- Tests: no Dart test change; verification is DB advisor + role smoke.

## Implementation Steps
1. On branch: `CREATE INDEX` for each of the 7 unindexed FKs (list from `get_advisors performance`). Safe, do first.
2. Rewrite policies to `(select auth.uid())` — mechanical, behavior-preserving.
3. Consolidate duplicate permissive policies per table/role/action, preserving combined access. One table at a time.
4. After each table: role smoke via `execute_sql` impersonation or app login (customer/manager/admin read+write still correct).
5. Re-run `get_advisors performance`; confirm counts dropped.
6. `merge_branch` only after all role smoke passes.

## Success Criteria
- [x] `auth.uid()`-init and unindexed-FK warns cleared (21→0, 7→0). Multiple-permissive-policies (120) intentionally NOT reduced — consolidation cut per RT-11 scope decision, not a miss.
- [x] All three roles retain correct read/write access (no RLS regression).

## Risk Assessment
- HIGHEST hygiene risk: policy consolidation can silently broaden or narrow access. Mitigate: change one table at a time, re-test each role's access on the branch before merge; keep the `auth.uid()` wrap (safe) separate from consolidation (risky) so a bad consolidation can be dropped without losing the perf win. Fully branch-gated.
