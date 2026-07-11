---
phase: 2
title: "Stock decrement oversell guard"
status: completed
effort: ""
---

# Phase 2: Stock decrement oversell guard

> ⚠️ **MERGED INTO [phase-01](./phase-01-voucher-discount-apply.md) by red-team (RT-6).** Stock decrement + oversell guard rewrites the same `create_order` body as voucher/shipping, so it ships as one serialized migration. This file is a pointer — execute the stock work as part of Phase 01. Key additions from red-team: lock `FOR UPDATE ORDER BY variant_id` (deadlock-safe), and **restock on cancel** (RT-3) — decrement without restock leaks inventory.

## Overview
Fix F2 (MED): nothing decrements `product_variants.stock_qty` — `create_order` never touches it and no trigger exists → unlimited oversell. Add atomic availability check + decrement inside `create_order`. **(Now part of Phase 01.)**

## Requirements
- Functional: for each item, if `stock_qty < quantity` → reject the whole order with a clear error; else decrement `stock_qty` by quantity atomically in the same transaction as order creation.
- Non-functional: race-safe (concurrent orders can't both pass the check for the last unit); idempotent migration.

## Architecture
In `create_order`'s item loop, `SELECT ... FROM product_variants WHERE id = v_variant_id FOR UPDATE` (row lock) alongside the existing price join; compare `stock_qty` vs `v_qty`; raise `insufficient stock for variant %` if short; after successful insert of order_items, `UPDATE product_variants SET stock_qty = stock_qty - v_qty WHERE id = v_variant_id`. All within the function's implicit tx so a later raise rolls back earlier decrements. Cancellation restock is out of scope (note it).

## Related Code Files
- Modify (DB branch migration): `create_order` (same function as Phase 1 — sequence after Phase 1 on the same branch).
- Verify client error surfacing: `FE/lib/blocs/checkout/checkout_bloc.dart` (show "hết hàng" style error).
- Tests: `FE/test/blocs/checkout_bloc_test.dart` + a DB-level check via `execute_sql` on branch.

## Implementation Steps (TDD)
1. Failing test: checkout where requested qty > stock → expect order failure + no stock change; success path → stock decremented. (Bloc test with mocked service for the error surface; DB behavior verified on branch.)
2. On the SAME Supabase branch as Phase 1: extend `create_order` migration with `FOR UPDATE` lock + check + decrement.
3. Branch test via `execute_sql`: (a) order within stock → stock_qty drops by qty; (b) order exceeding stock → raises, order + items rolled back, stock unchanged; (c) two concurrent orders for last unit → exactly one succeeds.
4. Client: map the raised error to a user-facing "Sản phẩm đã hết hàng" message in CheckoutBloc.
5. `merge_branch` after green.

## Success Criteria
- [ ] Oversell rejected (order fully rolled back, stock unchanged).
- [ ] Successful order decrements `stock_qty` by ordered quantity.
- [ ] Concurrent last-unit orders: exactly one succeeds.
- [ ] Existing + new tests green.

## Risk Assessment
- `FOR UPDATE` adds lock contention — acceptable at this scale. Cancellation does NOT restock (documented gap; separate plan if needed). Ensure decrement + insert share one tx so rollback is clean.
