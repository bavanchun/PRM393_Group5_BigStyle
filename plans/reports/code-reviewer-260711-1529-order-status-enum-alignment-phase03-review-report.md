# Code Review: Phase 03 — Order-Status Enum Alignment (F3)

Score: 6/10

## Scope
- Files: FE/lib/models/order_status.dart, FE/lib/models/order_model.dart, FE/lib/widgets/status_badge.dart,
  FE/lib/screens/manager/manager_order_card.dart, FE/lib/screens/orders/order_detail_screen.dart,
  FE/test/models/order_status_cancellable_test.dart, FE/test/models/order_status_from_map_test.dart (new)
- Verified independently: `flutter analyze` (0 issues), `flutter test` (109/109 pass)

## Critical — BLOCKING

### C1: DB enum does NOT have `processing`/`refunded`. Premise of F3 is false.
`FE/supabase/migrations/20260708140000_update_order_status_enum.sql` (lines 9-16) rebuilds
`order_status` down to exactly 5 values (pending, confirmed, shipping, delivered, cancelled).
Vietnamese comment: "-- 2. Tạo enum mới (bỏ processing, refunded)" = "create new enum (remove
processing, refunded)". No later migration (checked all 19 files under supabase/migrations/) re-adds
them. `grep -rn "processing\|refunded" supabase/migrations/*.sql` returns only this removal comment.

This means:
- `processing`/`refunded` can never be produced by `OrderModel.fromMap` against the real schema.
- All new code paths added by this phase (label branches, nextStatuses branches, `_buildTimeline`'s
  refunded-terminal-badge branch, manager read-only carve-out) are currently dead code.
- F3 as described ("processing/refunded orders silently render as Chờ xác nhận") cannot occur —
  the original 5-value `orElse: () => OrderStatus.pending` fallback was already correct and
  unreachable in practice.
- I do not have Supabase MCP tools in this session's toolset to run `select
  enum_range(null::order_status)` against the live project (agbnpqgxsppdrpbqoipo) to double-confirm.
  **Someone with DB access must run this before the phase is accepted.**

Action: if live DB confirms 5 values, revert/re-scope this phase — do not ship enum members that
can't be produced by real data, and treat "F3 fixed" claims as false. If live DB somehow has 7
values (out-of-band migration not tracked in this repo), that's a bigger problem: untracked schema
drift between `supabase/migrations/` and the live project, needing its own remediation.

## High Priority

### H1: `assert(false, ...)` in OrderModel.fromMap orElse — acceptable, conditioned on C1
Since DB truth (per migration) is 5 values and the fallback is unreachable for all 5, the assert only
fires for genuine data corruption / future drift. Stripped in release builds (assert is a no-op
outside debug/profile-with-asserts), so production keeps the silent pending fallback. Reasonable
tradeoff for a course project IF C1 resolves to "DB really has 5 values" — the assert's blast radius
is then unchanged from before this diff.

### H2: Adjacent pattern risk — payment status switches have no assert/log
`FE/lib/screens/manager/manager_order_detail_screen.dart` `_paymentStatusLabel`/`_paymentStatusColor`
switch on `payments.status` (different table/enum, not order_status) with silent `default:` catch-alls
mapping any unrecognized value to "Không có"/warning color. Out of scope for F3 but is the *actual*
shape of bug F3 was worried about — worth a future ticket, not this phase.

## Medium

### M1: Plan doc says "Add StatusColors entries" — correctly not done
processing/refunded reuse existing info/warning slots in status_colors.dart. Correct call (YAGNI),
but plan.md / phase file text is stale versus the actual diff.

### M2: `_buildTimeline` stepper math verified correct for processing's mid-list insertion
happyPath is now [pending, confirmed, processing, shipping, delivered] (5 elements). Loop is fully
driven by steps.length/currentIndex, no hardcoded position assumptions. Correct in isolation, though
per C1 it exercises a state unreachable against the real DB today.

## Verified Safe (no regressions)
- All switches exhaustive, 0 analyze issues.
- 109/109 tests pass (ran independently).
- manager_orders_screen.dart filter-chip list (`<OrderStatus?>[null, ...OrderStatus.values]`) handles
  8 chips fine — horizontal ListView.separated, no TabController/fixed-width dependency.
- revenue_recognition.dart / manager_dashboard_stats.dart string-based status checks are pre-existing,
  untouched, and correct regardless of C1 outcome.
- Existing 5-value behavior (label/isActive/happyPath/nextStatuses/isCancellable for
  pending/confirmed/shipping/delivered/cancelled) unchanged — diff is additive only.

## HARD-GATE-NO-SIDE-EFFECTS
PASS with caveat: no regression to existing 5-value flows. Only "side effect" is dead code for the 2
new enum values if C1 confirms DB has 5 values — inert, not harmful, but should not ship framed as a
fix for a real bug until C1 is resolved.

## Unresolved Questions
- Does live Supabase DB (agbnpqgxsppdrpbqoipo) actually have processing/refunded in order_status,
  contradicting migration 20260708140000? Needs verification by someone with Supabase MCP/CLI access
  before this phase is marked done.
