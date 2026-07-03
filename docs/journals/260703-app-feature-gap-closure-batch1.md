# App Feature Gap Closure (Batch 1) — Implementation Journal

Date: 2026-07-03 · Branch: dev · Plan: `plans/260703-2142-app-feature-gap-closure`

## What
Closed six audited gaps in one pass (push notifications deferred to a later plan):
1. **Avatar upload** — edit-profile pick → upload → `profiles.avatar_url`.
2. **Store map wiring** — profile "Cửa hàng" → real `DeliveryMapScreen`; "Chỉ đường" launches Google Maps (`url_launcher`).
3. **Manager variant color** — swatch drives real `color_hex` (dropped hardcoded `#914B34`).
4. **Size/Sale facets** — real variant-size + `sale_price` filters (were literal-text search / price sort).
5. **Order cancel + timeline** — customer self-cancel (pending/confirmed) + status stepper.
6. **Voucher MVP** — `vouchers` table + checkout promo + manager CRUD.

## Key decisions / architecture
- **`cancel_my_order` RPC (SECURITY DEFINER, atomic).** Customers have no UPDATE on
  `orders` (only INSERT/SELECT own). One-statement UPDATE with the status guard in
  the WHERE clause (no TOCTOU) + `SET search_path`. Reuses the existing
  `on_order_status_change` trigger for the notification.
- **`create_order` RPC = authoritative order writer.** The orders INSERT policy only
  checks `user_id`, so a client could post any subtotal/discount/total. Order
  creation now goes through a SECURITY DEFINER RPC that recomputes subtotal from
  `sale_price ?? base_price`, re-derives the discount via `validate_voucher`, and
  ignores client money — closing a pre-existing client-trusted-total hole.
- **`validate_voucher` RPC** clamps discount to `[0, subtotal]`; table CHECKs bound
  `value` (percentage ≤ 100). Codes stored/looked-up upper-cased.
- Facets added to `ProductState` with a `clearSize` flag; chips are single-select
  (each resets the other dimensions).

## Red-team (pre-implementation) — applied
Adversarial plan review verified against the live DB and folded in: atomic cancel,
`search_path` on both new definer functions, write-path discount enforcement,
discount clamp, content-anchored edits on the shared `order_detail` totals card.

## Bug caught in code review (fixed before ship)
- **Avatar upload broken for customers (HIGH):** reused the manager-only `products`
  storage bucket → customer uploads RLS-rejected (avatar silently never saved).
  Fixed: switched to the `avatars` bucket (made public; RLS path `<uid>/…`),
  generalized `uploadProductImage` with a `bucket` param.
- **Facet reset asymmetry (MED):** Size/Sale chips didn't clear category → stale
  combined filters. Made every chip fully exclusive.

## Verification
`flutter analyze` clean (only pre-existing debt). DB RPCs verified live:
`validate_voucher` (percentage cap 50k, min-order reject, case-insensitive);
`create_order` end-to-end (subtotal 30000, SALE10 → discount 3000, total 57000,
denormalized order_items, images handled) — test order removed after.
`cancel_my_order` auth/ownership guard verified (generic error, no info leak).

## Known limitations (deferred)
- Checkout total is a client preview; charged total is server-authoritative (match
  in normal flow). Order-item unit price on success screen is client-cached
  (cosmetic). Push notifications still out of scope (separate plan).
