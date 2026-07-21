---
phase: 5
title: "Shipping fee server-side"
status: completed
effort: ""
---

# Phase 5: Shipping fee server-side

> ⚠️ **MERGED INTO [phase-01](./phase-01-voucher-discount-apply.md) by red-team (RT-6).** Same `create_order` body as voucher/stock → one migration. This file is a pointer. Red-team RESOLVED the shipping model: flat **30.000đ** (`app_config.dart:22`), no 40k anywhere — server overrides `p_shipping_fee` with that constant. Distance-based is out of scope.

## Overview
Fix F4 (LOW): `create_order` inserts `p_shipping_fee` verbatim from the client — any authenticated user can pass an arbitrary fee. Derive/validate shipping server-side. **(Now part of Phase 01.)**

## Requirements
- Functional: server computes or validates `shipping_fee` rather than trusting the client. Default model = flat 30.000đ (confirm — see open question; distance-based via delivery map is the alternative).
- Non-functional: keep `create_order` signature stable; idempotent migration.

## Architecture
Two options depending on the shipping model decision:
- **Flat (default):** ignore/override `p_shipping_fee` with a server constant (30000) — or validate `p_shipping_fee` ∈ allowed set and reject otherwise.
- **Distance-based:** compute from `shipping_address` lat/lng vs store location (heavier; only if the delivery-map model is intended). Likely out of scope this round → keep flat, document.
Recommend: server-side flat constant to match `AppConfig.flatShippingFee`, single source of truth. Sequence after Phases 1–2 on the same branch (same RPC).

## Related Code Files
- Modify (DB branch migration): `create_order` (same function as Phases 1, 2).
- Verify: `FE/lib/config/app_config.dart` (`flatShippingFee`), `FE/lib/blocs/checkout/checkout_bloc.dart` (client still displays fee).
- Tests: DB branch test that a client-supplied bogus fee doesn't change the order total's shipping component.

## Implementation Steps (TDD)
1. Failing test/assertion (branch DB): call `create_order` with `p_shipping_fee = 999999` → resulting `orders.shipping_fee` = server value (30000), not the bogus input.
2. Migration: set `v_shipping := 30000` server-side (or validate against allowed set) in `create_order`.
3. Keep client display consistent (checkout still shows 30.000đ).
4. `merge_branch` after green.

## Success Criteria
- [ ] Server ignores/validates client shipping fee; order total uses the server value.
- [ ] Client checkout still shows the correct fee; tests green.

## Risk Assessment
- Low. If distance-based is later chosen, this becomes a bigger phase — defer that; document flat as the current model. Depends on open-question answer for shipping model.
