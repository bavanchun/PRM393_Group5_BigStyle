---
title: App Feature Gap Closure (Batch 1)
description: >-
  Close six audited feature gaps in BigStyle (Flutter + Supabase): avatar
  upload, store-map wiring, manager variant color persist, real size/sale
  product facets, customer order cancel + status timeline, and
  voucher/promo-code MVP at checkout. Push notifications (FCM) explicitly
  deferred to a separate plan.
status: completed
priority: P2
branch: dev
tags:
  - customer
  - manager
  - checkout
  - voucher
  - flutter
  - supabase
blockedBy: []
blocks: []
created: '2026-07-03T14:44:23.776Z'
createdBy: 'ck:plan'
source: skill
---

# App Feature Gap Closure (Batch 1)

## Overview

Six gaps surfaced by the full-app feature audit (see
`plans/reports/` audit outputs). Ordered **quick-wins first** so value ships
incrementally; the two heavier features (order cancel, voucher) come last.

**Key audit-confirmed facts that shrink scope:**
- `products.sale_price`, `orders.discount_amount`, `cart.promo_code`,
  `cart.discount_amount`, `profiles.avatar_url`, `product_variants.color_hex`,
  and `notifications.type='promotion'` **already exist** in the DB.
- `UserModel.avatarUrl` already in `copyWith`/`toMap` → avatar needs **no** model change.
- `DeliveryMapScreen` is fully built (Google Map + Directions) but **orphaned**.
- `image_picker` present; `url_launcher` **must be added** (phase 2).
- RLS: customers have **no UPDATE** on `orders` (only INSERT/SELECT own; manager
  ALL). Customer cancel therefore goes through a `SECURITY DEFINER` RPC, not a
  broad UPDATE policy.

**Stack:** Flutter + flutter_bloc + Supabase (Postgres, RLS, Storage). Mirrors
existing bloc/service/screen conventions.

## Locked decisions (from scope challenge)
- **#3 Push notification = OUT of scope** this plan → separate future plan.
- **Voucher = MVP**: `vouchers` table (percentage/fixed, min order, expiry,
  active), code entry at checkout, basic manager CRUD. No per-user usage caps,
  stacking, or auto-apply.
- **Order #1 = status timeline (derived from status, no carrier integration) +
  customer self-cancel when status ∈ {pending, confirmed}**.
- **Order cancel path = RPC `cancel_my_order`** (ownership + status guard), reuse
  existing `on_order_status_change` notification trigger.
- **Variant color = product-global swatch** drives `color_hex` (keep per-row
  color text as-is; just stop hardcoding the hex).

## Phases

| Phase | Name | Status |
|-------|------|--------|
| 1 | [Avatar Upload](./phase-01-avatar-upload.md) | Completed |
| 2 | [Store Map Wiring](./phase-02-store-map-wiring.md) | Completed |
| 3 | [Variant Color Persist](./phase-03-variant-color-persist.md) | Completed |
| 4 | [Size & Sale Facets](./phase-04-size-sale-facets.md) | Completed |
| 5 | [Order Cancel & Timeline](./phase-05-order-cancel-timeline.md) | Completed |
| 6 | [Voucher MVP](./phase-06-voucher-mvp.md) | Completed |

## Dependency Chain

```
Phase 1 (avatar)   ─┐
Phase 2 (map)       ├─ independent quick-wins, any order / parallelizable
Phase 3 (color)     │
Phase 4 (facets)   ─┘
Phase 5 (cancel+timeline) ── DB migration (RPC) + order bloc/detail
Phase 6 (voucher)         ── DB migration (table+RLS) + checkout + manager CRUD
```

Phases 1-4 own disjoint files → safe to run in parallel. Phases 5 and 6 each
carry a DB migration; run sequentially after the quick-wins. 5 and 6 touch
different areas (order vs checkout/voucher) but both read `OrderModel`/checkout
math — do 5 then 6 to avoid checkout-total merge friction.

## Acceptance Criteria (whole plan)

- [ ] Avatar: user picks image in edit-profile → uploaded → `avatar_url` saved →
      reflects in profile.
- [ ] Store: profile "Cửa hàng" opens the real `DeliveryMapScreen`; "Chỉ đường"
      launches external Google Maps.
- [ ] Manager: chosen color swatch persists real `color_hex` on new variants
      (no more hardcoded `#914B34`).
- [ ] Product list: "Size XL/2XL/3XL" filters by real variant size; "Sale"
      filters to on-sale products (`sale_price` set).
- [ ] Customer: cancel button on own pending/confirmed order → status becomes
      cancelled (via RPC, RLS-safe) → notification fired; order detail shows a
      status timeline.
- [ ] Voucher: valid code at checkout applies discount → `orders.discount_amount`
      persisted, total recomputed, discount row shown on checkout + order detail;
      manager can create/toggle vouchers.
- [ ] `flutter analyze` clean; no regressions to existing checkout/order/product flows.

## Out of Scope
- Push notifications / FCM (separate plan).
- Voucher per-user usage limits, stacking, auto-apply, customer voucher list.
- Real carrier shipment tracking (timeline is status-derived only).
- Avatar cropping; multiple store locations; distance-based shipping in checkout.

## Red-Team Applied
Adversarial review (verified against live DB) folded into phases 4-6:
- Order cancel = single atomic UPDATE with status guard (no TOCTOU); both new
  RPCs `SET search_path = public`.
- **Voucher discount enforced on the write path** via a `create_order`
  `SECURITY DEFINER` RPC (client money fields ignored) — not just previewed. This
  also closes a pre-existing client-trusted-`total` hole.
- Discount clamped `[0, subtotal]` + table CHECKs; `order_detail` edits anchored
  on content (not line numbers) to survive phase-5 line shifts.

## Open Questions — Resolved during implementation
1. **Order-write authority** → RESOLVED: implemented the `create_order` RPC
   (server-authoritative money). Verified end-to-end (subtotal from
   `sale_price ?? base_price`, discount clamp, denormalized items).
2. **Avatar storage bucket** → RESOLVED (code-review H1): the `products` bucket is
   manager-only, so customer avatars would never persist. Switched to the existing
   `avatars` bucket (made public; RLS requires path `<uid>/…`); generalized
   `uploadProductImage` with a `bucket` param.
3. **Voucher secrecy** → kept public SELECT of active codes (MVP default).

## Post-implementation notes (deferred minors from code review)
- M2: checkout total is a client preview; the charged/persisted total is the
  server value. In normal flow they match (same items/prices); a confirmation
  screen showing the server total would remove any divergence.
- L4: order-item `unit_price` on the success screen is the client-cached price
  (cosmetic); the authoritative subtotal is server-side.
- L6: voucher edit sheet keeps a stale `max_discount` when switching to `fixed`
  (harmless — `validate_voucher` ignores it for fixed).
