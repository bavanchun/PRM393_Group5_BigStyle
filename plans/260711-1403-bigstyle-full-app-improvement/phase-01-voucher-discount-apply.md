---
phase: 1
title: "Voucher discount apply"
status: pending
effort: ""
---

# Phase 1: Voucher discount apply

> ⚠️ **RED-TEAM OVERRIDE (authoritative — see plan.md `## Red Team Review`).** This phase is now the **merged `create_order` money-path hardening** = voucher (F1) + stock/oversell (F2, ex-phase-02) + server shipping (F4, ex-phase-05), as ONE serialized migration on ONE Supabase branch with ONE down-migration. Reasons: they all `create or replace` the same function; separate merges would clobber (RT-6).
> **Prerequisites before any migration:**
> - RT-1/RT-9: real source is `FE/supabase/migrations/20260708120000_create_order_rpc.sql` (NOT `FE/schema.sql`, which is a stale "CurveFit" snapshot). `vouchers` table + `validate_voucher` are **not in the repo** — first repatriate their DDL from prod (`pg_get_functiondef('public.validate_voucher'::regproc)`, table DDL) into a baseline migration, else the branch has no such function and checkout breaks.
> - RT-1: verify `validate_voucher`'s real invalid-input contract (RAISE vs return 0 vs return NULL) against the live definition — do not assume.
> **Money-path invariants to add:**
> - RT-4: `v_discount := greatest(least(coalesce(v_discount,0), v_subtotal), 0)` BEFORE `v_total := v_subtotal + v_shipping - v_discount` (no NULL total, discount never exceeds subtotal / eats shipping).
> - RT-2: enforce voucher redemption atomically (unique `voucher_redemptions` row or `used_count`/`usage_limit` guarded `FOR UPDATE`). Unlimited reuse of a real discount is a money exploit. <!-- Updated: Validation V1 — DECIDED: enforce redemption (vouchers ARE limited); NOT unlimited-public. Add redemption tracking + atomic guard. -->
> - V4 (branch origin): repatriate `vouchers`+`validate_voucher` DDL into repo migrations FIRST, then build the Supabase branch FROM repo migrations (faithful + reproducible) — not a prod clone.
> - RT-3: add restock to `cancel_my_order` (+ any admin/refund cancel) in THIS phase — decrement without restock leaks inventory permanently on the 6 cancellable live orders.
> - Stock (ex-phase-02): lock variants `FOR UPDATE` **ordered by variant_id** (deadlock-safe for multi-variant carts), reject if `stock_qty < qty`, decrement after insert.
> - Shipping (ex-phase-05): override `p_shipping_fee` with server constant **30.000đ** (`AppConfig.flatShippingFee`; RT confirms 30k not 40k).
> - RT-8: ship a paired **down-migration** (restore prior full `create_order` body) + pre-merge check that existing `pending`/`confirmed` orders still read/return an identical row shape (client + payment-watch consume it).
> One regression test must assert all three invariants on the FINAL function body (discount applied AND stock decremented AND server shipping) so a later clobber fails CI.

## Overview
Fix F1 (HIGH): `create_order` RPC hard-stubs `v_discount := 0`, so vouchers never reduce the order total though the client shows a preview discount. Make the RPC apply the server-validated voucher discount — now folded into the merged money-path phase above.

## Requirements
- Functional: when a valid `p_promo_code` is passed, `orders.discount_amount` and `orders.total` reflect the discount computed by `validate_voucher(p_code, subtotal)`; invalid/expired/below-min codes cause the order to fail (or apply 0) consistently with the checkout preview.
- Non-functional: keep server-authoritative pricing; single source of truth for discount = `validate_voucher`; idempotent migration.

## Architecture
`create_order` currently computes `v_subtotal` then sets `v_discount := 0`. Replace with: after subtotal loop, if `p_promo_code` non-empty → `v_discount := public.validate_voucher(p_promo_code, v_subtotal)` (SECURITY DEFINER, already returns numeric or raises). Clamp `v_total := max(v_subtotal + p_shipping_fee - v_discount, 0)`. Decide error semantics: raising aborts order (matches "voucher invalid" UX) — preferred over silently charging full price. Confirm `validate_voucher` raise vs return-0 behavior and align.

## Related Code Files
- Modify (DB, via Supabase branch migration): `create_order` function (see live def in test report; source likely in `FE/schema.sql` or a migration under `FE/`).
- Verify client: `FE/lib/blocs/checkout/checkout_bloc.dart`, `FE/lib/services/order_service.dart` (`createOrderViaRpc`), `FE/lib/services/voucher_service.dart` (preview `validate`).
- Tests: `FE/test/blocs/checkout_bloc_test.dart` (extend).

## Implementation Steps (TDD)
1. Write failing test: checkout with a valid seeded voucher asserts final total = subtotal + shipping − expected discount (bloc-level, mock OrderService returning RPC result with non-zero discount_amount). Lock current COD/empty-guard tests stay green.
2. On a Supabase branch: `create_branch` → migration replacing the `v_discount := 0` stub with a `validate_voucher` call + clamp. Keep function signature identical.
3. Test on branch via `execute_sql`: create order with a valid voucher (subtotal above min) → assert discount_amount > 0 and total correct; with invalid code → assert consistent behavior (raise or 0 per decision).
4. Reconcile client: ensure CheckoutBloc surfaces a raised voucher error gracefully (already shows preview error path).
5. `merge_branch` after green.

## Success Criteria
- [ ] Valid voucher: `orders.discount_amount` = validated discount, `orders.total` reduced accordingly.
- [ ] Invalid/expired/below-min voucher handled consistently with checkout preview (no silent full charge).
- [ ] Existing 104 tests + new voucher test green; `flutter analyze` 0.

## Risk Assessment
- Money-path change → TDD + branch test before merge. If `validate_voucher` raises inside `create_order`, the whole order aborts (order_items already inserted in same tx → rolled back; verify tx boundary). Mitigation: confirm the function runs in a single implicit tx (plpgsql) so partial inserts roll back on raise.
