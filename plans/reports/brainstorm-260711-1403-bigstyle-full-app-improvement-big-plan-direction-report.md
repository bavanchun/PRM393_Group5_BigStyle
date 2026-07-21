# Brainstorm — BigStyle Full-App Improvement Big Plan (Direction)

**Date:** 2026-07-11 14:03 | **Branch:** `dev` | **Model:** Opus 4.8 | **Mode:** brainstorm (no `--html`/`--wiki`)
**Inputs:** [test report](qa-260711-1220-bigstyle-full-app-test-automated-backend-report.md) · [scout report](scout-260711-1208-bigstyle-full-app-architecture-map-report.md)
**Handoff:** `/ck:plan --tdd` (refactors money-path + critical logic; 104 existing tests to preserve)

## Problem statement
Test pass surfaced verified defects (1 HIGH money bug + several MED) plus security/perf hygiene, a data-quality issue, and coverage gaps. Need one coherent big plan to fix + harden + verify, safely against a **live prod Supabase** DB.

## Findings → groups
- **A. Correctness / money (user-facing):** F1 voucher discount hard-stubbed to 0 (HIGH), F5 manager dashboard "Khách hàng"=0 (MED), F3 order_status enum DB(7) vs Dart(5) → processing/refunded mislabel as pending (MED).
- **B. Data integrity:** F2 no stock decrement → oversell (MED), F4 create_order trusts client shipping_fee (LOW).
- **C. Security/perf hygiene (DB):** 2 funcs mutable search_path (notify_order_update, update_sold_count); trigger-funcs exposed via REST RPC; 2 public buckets allow listing; leaked-password protection off; RLS perf — 120 multiple-permissive-policies, 21 bare `auth.uid()` (unwrapped), 7 unindexed FKs.
- **D. Data cleanup:** catalog all 10.000đ test-junk pricing.
- **E. Verification harness:** 5 zero-row features (reviews/wishlist/chat/support) never exercised e2e; native flows (maps/geo/image-picker/google/SePay) unverified — blocked on `/dev/kvm` (needs `sudo modprobe kvm_amd`).

## Decisions (user-confirmed)
1. **F2:** implement stock decrement + oversell rejection inside `create_order` (atomic check-and-decrement). Not backorder.
2. **Scope:** ALL groups A→E in one big plan (incl. verification harness E).
3. **DB migrations:** go through a **Supabase branch** — apply + test on a copy, then merge. Safer for prod with real data.

## Recommended solution — phase shape (for /ck:plan to expand)
DB work isolated on a Supabase branch; each code phase TDD (lock behavior first). Ordered by impact + dependency:

1. **Voucher discount (F1)** — `create_order` calls `validate_voucher(p_promo_code, subtotal)`, applies returned discount to `discount_amount`/`total`; single source of truth. Migration + bloc/regression test.
2. **Stock decrement + oversell guard (F2)** — in `create_order`, per item `select … for update` variant, reject if `stock_qty < qty`, else decrement. Migration + tests (incl. oversell rejection, concurrent).
3. **Order-status enum alignment (F3)** — add `processing` + `refunded` to Dart `OrderStatus` (label, `nextStatuses`, StatusColors); decide manager transitions. Tests for fromMap + state machine.
4. **Manager dashboard customer count (F5)** — fix stats query to count customer profiles correctly. Test.
5. **Shipping fee server-side (F4)** — derive/validate `shipping_fee` in `create_order` (use `AppConfig.flatShippingFee` equivalent server-side), stop trusting client. Migration + test.
6. **Security hygiene (C-sec)** — pin `search_path` on the 2 funcs; `REVOKE EXECUTE` on trigger-only funcs from anon/authenticated; tighten public-bucket SELECT (drop broad listing); enable leaked-password protection (auth config). Migration + config.
7. **RLS/perf hygiene (C-perf)** — wrap `auth.uid()` → `(select auth.uid())` in policies; consolidate duplicate permissive policies; add indexes for 7 FKs. Migration.
8. **Data cleanup (D)** — set realistic catalog prices (seed/update script); remove test-junk 10.000đ uniformity.
9. **Verification harness (E)** — after KVM enabled: e2e exercise reviews/wishlist/chat/support (create real rows) + native flows (maps/geo/picker/google/SePay) on emulator; capture results. Test/verification phase (depends on `sudo modprobe kvm_amd`).

## Risks
- **Prod DB migrations** — mitigate via Supabase branch test→merge; keep each migration idempotent; snapshot before merge.
- **create_order is the money path** — F1/F2/F4 all touch it; sequence carefully, TDD, don't break server-authoritative pricing already verified working.
- **F3 enum change** — ensure fromMap round-trips all 7; verify manager status-update UI doesn't offer illegal transitions.
- **E depends on KVM** — hard blocker; phase 9 stalls until user runs `sudo modprobe kvm_amd`. Keep phases 1–8 independent of it.
- **RLS policy consolidation (C-perf)** — risky if it changes access semantics; test each role's read/write after.

## Success metrics
- Voucher: applying a valid code reduces order.total by the exact validated discount (server-verified).
- Stock: oversell attempt rejected; stock_qty decrements on successful order.
- Enum: a `processing`/`refunded` order renders its true label (not "Chờ xác nhận").
- Dashboard: "Khách hàng" reflects real customer count.
- `flutter analyze` 0, full `flutter test` green (incl. new regression tests), Supabase advisors: the addressed warns cleared.
- E: each of the 5 features has ≥1 real e2e row + native flows demonstrated.

## Next steps
Hand to `/ck:plan --tdd` (Opus 4.8) with this report → produce `plans/<slug>/plan.md` + phase files (9 phases above), DB work flagged Supabase-branch, each phase with tests/acceptance. Cook executed separately (Sonnet 5) per project rules.

## Unresolved (surface in plan)
- F3: should managers be able to set `processing`/`refunded` from the app, or are those webhook/admin-only? (Affects state-machine transitions.)
- F4: confirm flat 30.000đ is the intended shipping model (vs distance-based via the delivery map) before hardcoding server-side.
- D: who defines the "realistic" price list — reuse order-captured prices or a fresh catalog?
