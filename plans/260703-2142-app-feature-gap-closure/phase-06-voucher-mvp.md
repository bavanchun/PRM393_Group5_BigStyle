---
phase: 6
title: Voucher MVP
status: completed
priority: P1
dependencies: []
---

# Phase 6: Voucher MVP

## Overview
Add promo-code discounts. Customer enters a code at checkout → validated → discount
applied to the order total and persisted to `orders.discount_amount`. Manager gets
a basic voucher CRUD (create + toggle active). Replaces the dashboard "Khuyến mãi"
coming-soon stub.

## Requirements
- Functional: valid code (active, not expired, order ≥ min) reduces total by a
  percentage or fixed amount; invalid/expired code shows an error and no discount;
  discount row shows on checkout + order detail; manager creates/toggles vouchers.
- Non-functional: discount validated server-side (RPC) so the client can't invent
  a discount; `discount_amount` persisted with the order.

## Architecture
DB already has `orders.discount_amount` and `cart.promo_code`/`cart.discount_amount`
(unused). Add a `vouchers` table + RLS and a `SECURITY DEFINER` RPC
`validate_voucher(p_code, p_subtotal)` for the checkout UI preview. Manager CRUD
mirrors the existing `ManagerCategory` bloc/screen pattern.

**CRITICAL (red-team HIGH) — discount must be enforced on the WRITE path, not just
previewed.** Today `createOrder` inserts `OrderModel.toMap()` directly and the
orders INSERT policy only checks `user_id = auth.uid()`, so a client can POST any
`subtotal`/`discount_amount`/`total` (e.g. total 0) straight to PostgREST.
`validate_voucher` alone gives zero write-path enforcement. Therefore this phase
**moves order creation into a `SECURITY DEFINER` RPC `create_order`** that:
recomputes `subtotal` from the real variant prices of the submitted items,
re-derives the discount by calling `validate_voucher(p_code, recomputed_subtotal)`
server-side, computes `total = subtotal + shipping_fee - discount`, and inserts the
order + items — **ignoring any client-sent money fields**. The checkout UI still
shows a live preview via `validate_voucher`, but the persisted numbers come from
the server. This also closes the pre-existing client-trusted-`total` hole.
(If the team decides to accept the pre-existing risk for the demo and skip
`create_order`, see Open Questions — but the discount preview must then be clearly
labelled as non-authoritative.)

**`vouchers` table (MVP columns):**
`id uuid pk, code text unique not null, type text check in ('percentage','fixed'),
value numeric not null check (value >= 0), min_order_amount numeric default 0,
max_discount numeric null (cap for percentage), expires_at timestamptz null,
is_active boolean default true, created_at timestamptz default now()`.
Add `check (type <> 'percentage' or value <= 100)` so a percentage can't exceed
100% (red-team #4).

## Related Code Files
- Create (DB migration via `apply_migration`):
  - `vouchers` table + RLS policies (`Anyone can view active vouchers` SELECT
    `is_active = true`; `Managers manage vouchers` ALL `is_manager()`).
  - RPC `validate_voucher(p_code text, p_subtotal numeric) returns numeric`
    (`SECURITY DEFINER`, `SET search_path = public` — red-team #3) — look up active
    non-expired code with `p_subtotal >= min_order_amount`; compute discount then
    **clamp** so it never exceeds subtotal or goes negative (red-team #4):
    percentage → `d := round(p_subtotal * value / 100)`, then
    `d := least(d, coalesce(max_discount, d))`; fixed → `d := value`; finally
    `d := greatest(0, least(d, p_subtotal))`. Raise on not-found/expired/below-min.
  - RPC `create_order(...)` (`SECURITY DEFINER`, `SET search_path = public`) —
    authoritative order writer (see Architecture): recompute subtotal from variant
    prices, re-derive discount via `validate_voucher`, insert order + items,
    ignore client money fields. Returns the created order (with `order_number`).
- Create: `FE/lib/models/voucher_model.dart` — mirror `CategoryModel` style.
- Create: `FE/lib/services/voucher_service.dart` — `validate(code, subtotal)` via
  `rpc('validate_voucher')`; manager `list()/create()/toggleActive()`.
- Modify: `FE/lib/screens/checkout/checkout_screen.dart`
  - Add a promo-code `AppTextField` + "Áp dụng" button as a new section just
    before the summary Container (~line 213). State: `_promoCode`, `_discountAmount`.
  - Add a `_buildPriceRow('Giảm giá', -_discountAmount)` between "Phí vận chuyển"
    and the Divider (~line 227); recompute `total = subtotal + _shippingFee - _discountAmount`.
  - Pass `discountAmount: _discountAmount` into `_placeOrder()`'s dispatch.
- Modify: `FE/lib/blocs/checkout/checkout_event.dart` — add `discountAmount`
  (and optional `promoCode`) to `CheckoutPlaceOrder`.
- Modify: `FE/lib/services/order_service.dart` — replace the direct-insert
  `createOrder` write path with a call to the `create_order` RPC (pass items,
  address, shipping_fee, payment_method, promo_code); keep the return shape
  (`OrderModel` with `orderNumber`). Manager reads unchanged.
- Modify: `FE/lib/blocs/checkout/checkout_bloc.dart` — `_onPlaceOrder`: stop
  computing/sending authoritative money; forward `promoCode` + items to the RPC
  path. UI preview `total` still shown from `validate_voucher`, but persisted
  numbers come from the server. (`OrderModel.toMap` no longer trusted for the
  insert — the RPC owns money.)
- Modify: `FE/lib/screens/orders/order_detail_screen.dart` — render a "Giảm giá"
  row (`-discountAmount`) **immediately above the `Tổng cộng` (total) row** in the
  totals card, guarded by `order.discountAmount != null && order.discountAmount! > 0`.
  Anchor on the total-row content, NOT line numbers (red-team #5: phase 5 shifts
  this file's lines). Complements phase 5's edits to the same file.
- Create: `FE/lib/blocs/manager_voucher/…` + `FE/lib/screens/manager/vouchers/…`
  — list + create/edit sheet, mirroring `ManagerCategory*`.
- Modify: `FE/lib/screens/manager/manager_dashboard.dart` +
  `manager_dashboard_widgets.dart` — wire the "Khuyến mãi" quick action
  (`onComingSoon` → `_openVoucherManager`), same pattern as "Danh mục".
- Modify: `FE/lib/main.dart` — provide `ManagerVoucherBloc` app-wide.

## Implementation Steps
1. Migration: `vouchers` table + RLS + `validate_voucher` RPC; seed 1-2 demo codes.
2. Model + service (`validate`, manager CRUD).
3. Checkout: promo input + apply → call `validate` → set `_discountAmount` or show
   error; discount row; recompute total; thread into place-order.
4. Checkout bloc/event: carry `discountAmount`; persist via existing `OrderModel`.
5. Order detail: show discount row (guarded).
6. Manager voucher bloc + list/edit screen; wire dashboard quick action; provide
   bloc in `main.dart`.
7. Verify end-to-end: apply code → order row has `discount_amount` + reduced total.

## Success Criteria
- [ ] Valid code reduces total; `orders.discount_amount` persisted (verify DB).
- [ ] Expired/invalid/below-min code → error, no discount applied.
- [ ] Discount row visible on checkout and order detail.
- [ ] Manager creates a voucher and toggles it active/inactive; inactive code
      rejected at checkout.
- [ ] "Khuyến mãi" dashboard action opens the voucher manager (no coming-soon).
- [ ] `flutter analyze` clean; COD + bank-transfer checkout still work.

## Risk Assessment
- **Client-trusted discount/total (red-team HIGH)**: PostgREST insert policy only
  checks `user_id`, so a client could persist any discount/total. Mitigation:
  `create_order` `SECURITY DEFINER` RPC recomputes subtotal + discount server-side
  and ignores client money fields; `validate_voucher` is preview-only.
- **SECURITY DEFINER hygiene (#3)**: both RPCs set `search_path = public`.
- **Negative/over-subtotal discount (#4)**: clamp `greatest(0, least(d, subtotal))`
  + table CHECKs on `value`.
- **Voucher code enumeration (#6)**: public SELECT on active vouchers exposes all
  live codes. Acceptable for MVP; if "secret" codes wanted, drop the public SELECT
  policy and look up only via `validate_voucher`.
- Total mismatch between preview and persisted order. Mitigation: server total is
  source of truth; after place, reload order to show authoritative numbers.
- Scope creep (usage limits/stacking) — explicitly OUT; single code, no stacking.
- Cross-phase edit of `order_detail_screen.dart` with phase 5. Mitigation: run
  phase 5 first; anchor phase-6 edits on content (total row), not line numbers.
