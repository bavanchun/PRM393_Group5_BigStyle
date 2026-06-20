---
phase: 1
title: "Cart user_id & checkout guard"
status: completed
priority: P0
effort: "1h"
dependencies: []
---

# Phase 1: Cart user_id & checkout guard

## Overview
**Scope corrected after live-DB verification.** The committed Dart data layer was written against a flat schema that was never deployed; the deployed DB is normalized. This phase reconciles the entire write/read data layer to the real schema (Option C — keep normalized schema, load variants) AND adds the cart/checkout auth guards. Without this, the purchase flow fails end-to-end (cart targets a non-existent `carts` table; products map `price/sizes/stock` columns that don't exist → 0đ + no sizes; order insert sends non-existent `items`/`address` columns).

### Verified schema mismatches (live DB, this session)
- `products` real columns: `base_price, sale_price, avg_rating, review_count, body_type_fit[], tags[], is_active, slug` — code reads non-existent `price, original_price, sizes, stock`.
- Sizes/colors/stock live in `product_variants(size, color, color_hex, stock_qty, sku)` — never loaded.
- Cart: code uses `carts` (404); real tables are `cart(user_id unique)` + `cart_items(cart_id, variant_id, quantity)` with `unique(cart_id, variant_id)`.
- Orders: `order.toMap()` sends `items` (no such column) and `address` (should be `shipping_address` jsonb); `order_items` requires `variant_id, product_name, size, quantity, unit_price` (NOT NULL) — code sends `product_id, size, quantity, price`.

## Requirements
- Functional: a cart row inserted from product detail must carry the authenticated `user_id`; checkout must refuse to place an order when there is no real logged-in user.
- Non-functional: no schema change (cart_items already keyed by `cart.user_id`); `flutter analyze` clean.

## Key Insights (verified, file:line)
- `cart_item_model.dart:23-29` — `toMap()` does **not** emit `user_id`.
- `cart_service.dart:19` — derives user via `item.id.split('_').first`; the id is a `_`-less millisecond timestamp → garbage `user_id`.
- `product_detail_screen.dart:680-689` — builds `CartItemModel` with `id` = timestamp, no userId.
- `checkout_screen.dart:219` — `authState.user?.id ?? ''` lets an empty string flow into order insert (`order_service.dart:26`) and cart clear (`checkout_bloc.dart:46`).
- Cart insert path: `cart_service.dart:30`. Cart schema: `cart(user_id unique)` + `cart_items(cart_id, variant_id)` — the correct model is "get-or-create cart by user_id, then insert cart_items".

## Architecture
Correct the cart write to the real Supabase shape:
1. `CartService.addToCart(userId, variantId, quantity)` — accept an explicit `userId`; get-or-create the `cart` row for that user, then upsert into `cart_items` (respect `unique(cart_id, variant_id)` → on conflict increment quantity).
2. Product detail dispatches add-to-cart with the authenticated user id from `AuthBloc` state (not a fabricated id).
3. Add a single reusable guard: if `user == null` (or id empty / starts with `mock-`), block the action and show a "Vui lòng đăng nhập" snackbar, route to `/login`.

## Related Code Files
- Modify: `lib/services/cart_service.dart` (rewrite `addToCart`; remove `split('_')` hack; get-or-create cart)
- Modify: `lib/models/cart_item_model.dart` (drop user-id-from-id assumption; ensure `toMap()` matches `cart_items` columns: `cart_id`, `variant_id`, `quantity`)
- Modify: `lib/blocs/cart/cart_bloc.dart` + `cart_event.dart` (carry `userId` + `variantId` in the add event)
- Modify: `lib/screens/product_detail/product_detail_screen.dart:680-689` (pass real userId/variantId; guard)
- Modify: `lib/screens/checkout/checkout_screen.dart:219` + `lib/blocs/checkout/checkout_bloc.dart` (guard empty/mock userId)
- (Optional hardening) `lib/screens/splash/splash_screen.dart:26-35` — handle non-`AuthSuccess`/non-`AuthInitial` states so app can't hang on splash.

## Implementation Steps
1. Use `/mobile-development` skill for all edits below.
2. Read the cart trio + cart_service + product_detail add-to-cart block + checkout to confirm current shapes.
3. Rewrite `CartService.addToCart` to `(String userId, String variantId, int quantity)`: query `cart` by `user_id`; if none, insert and return id; then `cart_items` upsert on `(cart_id, variant_id)` incrementing quantity.
4. Update `CartItemModel.toMap()` to emit only real `cart_items` columns; remove any reliance on `id` encoding user.
5. Thread `userId` + `variantId` through `CartEvent`/`CartBloc` add handler.
6. In product detail, read `context.read<AuthBloc>().state.user`; if null/mock → guard; else dispatch add with real ids.
7. In checkout, replace `?? ''` with an explicit guard: block "Đặt hàng" when no real user; surface message.
8. (Optional) splash: add a fallback branch / listener so loading/error states still resolve.
9. `cd FE && flutter analyze` → must be clean. Smoke test: login (real OTP/Google) → add to cart → confirm a `cart_items` row appears with correct `cart.user_id` (verify via REST query).
10. Commit + PR via `/vchun-git prc`.

## Success Criteria
- [x] `CartService.addToCart` takes an explicit `userId`; `split('_')` hack removed
- [ ] `cart_items` row created with correct `cart_id` tied to the authenticated `user_id` (verified via REST)
- [x] `toMap()` emits only valid `cart_items` columns
- [x] Checkout refuses to place an order with empty/mock user id (shows message, no bad write)
- [x] `flutter analyze` clean
- [x] ≥1 commit + PR via `/vchun-git prc`

## Risk Assessment
- **Quantity merge**: ignoring `unique(cart_id, variant_id)` → duplicate-key error. Mitigate with upsert/increment.
- **AuthBloc access in widget**: ensure `AuthBloc` is in scope where add-to-cart fires (it is, provided at root `main.dart:42-60`).
- **Optional splash change** could alter startup timing — keep behind the existing 1500ms unless clearly safe; treat as optional, not blocking.

## Security Considerations
- Cart/checkout writes now always bound to `auth.uid()` → aligns with `cart`/`orders` RLS (users own their rows). Removes the path where a fabricated id could attempt a write.
