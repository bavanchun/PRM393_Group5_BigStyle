---
phase: 3
title: "Customer Purchase-Flow Blockers"
status: pending
priority: P1
dependencies: [1]
effort: "L"
---

# Phase 3: Customer Purchase-Flow Blockers

## Overview

Fix the P1 defects on the main customer demo path so browse→cart→checkout→orders works end-to-end without wrong data or dead-ends. Covers C15, C16, C11, C12, C6, C7, C28, C29, C35, and the pending-order recovery C24/C22.

## Requirements

- Functional: persisted cart loads on app start/login; cart empties after order (COD + bank); "Mua ngay" navigates once and never adds the wrong color; category chips/home-category navigation actually filter; order detail never spins forever; edit-profile only claims success after the bloc confirms; a stuck pending bank_transfer order has a "Thanh toán lại" path.
- Non-functional: no event dispatched inside `build()`; snackbars/navigation don't race.

## Architecture & Findings (verified file:line)

- **C15 — cart never loads (`cart_bloc.dart:10`, `cart_event.dart:12,50`):** grep confirms `CartLoad(` / `CartClear(` have **zero dispatch sites** repo-wide; handlers exist but are never triggered. A returning user's DB cart is never fetched.
- **C16 — COD doesn't clear CartBloc (`checkout_bloc.dart:88`, `payment_bloc.dart:47`):** both call `_cartService.clearCart(...)` **directly**, bypassing `CartBloc`, so in-memory `CartState.items` + badge stay stale after order.
- **C11 — buy-now double-nav (`product_detail_screen.dart:717-746`):** `_buyNow` calls `_addToCart()` then unconditionally `pushNamed('/cart')`; but `_addToCart` itself pushes `/login` for unauth/mock users → stacked navigation; happy path also races an "added" snackbar against the nav.
- **C12 — wrong-color fallback (`product_detail_screen.dart:686-694`):** variant resolution falls back size-only (any color) then `.first` → silently adds a different color than selected, no warning.
- **C7 — category args ignored (`product_list_screen.dart:35-40`):** `initState` never reads `ModalRoute…arguments`; list always opens unfiltered.
- **C6 — filter by label string (`product_list_screen.dart:357-362`):** dispatches `FilterByCategory('đầm'|'áo'|'quần')` — lowercased VN display label, not a real category id → matches nothing. (Confirm `product_bloc._onFilterByCategory` + product category field — see open Q.)
- **C28 — load in build() (`order_detail_screen.dart:16-17`):** StatelessWidget dispatches `OrderLoadDetail` inside `build()` → re-fires every rebuild.
- **C29 — infinite spin (`order_detail_screen.dart:25-27`):** `isLoading || order==null` → spinner with no error/not-found branch; stale `selectedOrder` from prior order.
- **C35 — optimistic profile save (`edit_profile_screen.dart:136-141`):** dispatches update, then **unconditionally** pops + shows "Cập nhật thành công" without awaiting; `auth_bloc.dart:109-119` can emit `AuthError` that's never seen.
- **C24/C22 — pending order stuck (`orders_screen.dart:63-129`):** order card is tap-only; no pay-again/cancel; a pending bank_transfer has no route back to the QR screen.

## Related Code Files

- Modify: `FE/lib/blocs/cart/cart_bloc.dart` (ensure handlers fine), and **dispatch sites**: on auth success / app start (near `main.dart` or a top-level `AuthListener`) → `CartLoad(userId)`; after order success → `CartClear(userId)`.
- Modify: `FE/lib/blocs/checkout/checkout_bloc.dart:88`, `FE/lib/blocs/payment/payment_bloc.dart:47` — emit/trigger `CartClear` via `CartBloc` instead of (or in addition to) direct `clearCart`, so state+badge update.
- Modify: `FE/lib/screens/product_detail/product_detail_screen.dart:642-746` — `_addToCart` returns success bool; `_buyNow` only navigates on success; no-variant-match → "hết hàng" message instead of `.first`.
- Modify: `FE/lib/screens/product_list/product_list_screen.dart:35-40,357-370` — read category arg in `didChangeDependencies`; map chip → real categoryId; 'Sale' → filter `hasDiscount`.
- Modify: `FE/lib/screens/orders/order_detail_screen.dart` — convert to Stateful + `initState` load; add error/not-found branch; reset selection on load.
- Modify: `FE/lib/screens/orders/orders_screen.dart:63-129` — add status-aware actions (pay-again → `/payment-qr` with order args; cancel/reorder).
- Modify: `FE/lib/screens/profile/edit_profile_screen.dart:124-141` — `BlocListener`: pop + success snackbar only on `AuthSuccess`; show error on `AuthError`.
- Reference: `product_bloc.dart` (`_onFilterByCategory`), `order_bloc.dart` (initial `isLoading`) — confirm before coding C6/C29.

## Implementation Steps

1. **Cart lifecycle (C15/C16):** add `CartLoad(userId)` dispatch on `AuthSuccess` (app start + login). Replace/augment direct `clearCart` in checkout+payment blocs so `CartBloc` receives `CartClear` → items + badge reset for **both** COD and bank paths.
2. **Buy-now (C11/C12):** refactor `_addToCart` → `Future<bool>`; return false on auth-redirect / out-of-stock. `_buyNow` awaits and only `pushNamed('/cart')` on true. Remove size-only + `.first` fallback; if no exact size+color variant → show "Sản phẩm đã hết size/màu này".
3. **Category filter (C6/C7):** read passed category id in `didChangeDependencies`, set filter; generate chips from `state.categories` and dispatch `FilterByCategory(categoryId)` matching by id. Verify against `product_bloc`.
4. **Order detail (C28/C29):** Stateful + `initState` one-time load; add `state.error`/not-found branch with retry; clear `selectedOrder` before loading a new id.
5. **Edit profile (C35):** wrap in `BlocListener<AuthBloc>`; pop + "thành công" only on success; snackbar error on failure; disable save while pending.
6. **Pending-order recovery (C24/C22):** on orders list, for `bank_transfer` + `pending`, show "Thanh toán lại" → navigate to `/payment-qr` with the order's args; add cancel for pending.
7. `flutter analyze` clean.

## Success Criteria

- [ ] Log in on a fresh device → previously-persisted cart appears (C15).
- [ ] Place COD order → cart empties + badge clears immediately (C16); same for bank-paid.
- [ ] "Mua ngay" navigates once; selecting a size/color with no variant shows out-of-stock, never adds a different color (C11/C12).
- [ ] Tapping a home category / chip filters the list to that category (C6/C7).
- [ ] Order detail shows content or an error+retry, never an infinite spinner (C28/C29).
- [ ] Edit profile shows success only when the update actually succeeds (C35).
- [ ] A pending bank_transfer order offers "Thanh toán lại" back to the QR (C24/C22).
- [ ] `flutter analyze` clean.

## Risk Assessment

- **Depends on Phase 1:** C15 is only demonstrable with a real logged-in customer that has a persisted DB cart — seed or add-then-relaunch.
- **C6 uncertainty:** the exact category-match logic lives in `product_bloc` (not yet read). Confirm whether it matches on name or id before choosing the chip→id mapping; wrong assumption = still-empty filter.
- **Cart clear ordering:** if `CartClear` fires before the success dialog reads cart totals, verify the dialog uses order snapshot data, not live cart, to avoid showing 0.
- **Double-clear:** payment bloc already clears directly; ensure adding `CartClear` doesn't double-delete or error on an already-empty cart.
