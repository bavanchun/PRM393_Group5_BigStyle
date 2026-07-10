---
phase: 3
title: "Checkout And Error-State Guards"
status: completed
priority: P1
effort: "1d"
dependencies: [2]
---

# Phase 3: Checkout And Error-State Guards

## Overview

Add low-risk UX guards around empty checkout and make existing error states
visible so network/backend failures stop looking like empty data.

## Requirements

- Functional: Checkout must not dispatch `CheckoutPlaceOrder` when no items are
  selected/available.
- Functional: Cart, orders, home/product sections, and notifications must render
  error + retry where state already exposes `error`.
- Functional: `NotificationsScreen` must stop dispatching `NotificationLoad`
  from `build()`.
- Non-functional: Keep existing BLoC architecture. No global error framework.

## Architecture

Use existing state fields:

```text
CartState.error
OrderState.error
ProductState.error
NotificationState.error
```

Convert `NotificationsScreen` from `StatelessWidget` to `StatefulWidget`.
Load once in `initState`/post-frame and provide retry.

## File Inventory

| File | Action | Size/Risk | Test impact |
|------|--------|-----------|-------------|
| `FE/lib/screens/checkout/checkout_screen.dart` | Modify | 690 lines | Add empty selected-items guard test/manual |
| `FE/lib/screens/cart/cart_screen.dart` | Modify | 290 lines | Error state widget test later |
| `FE/lib/screens/orders/orders_screen.dart` | Modify | 187 lines | Error vs empty widget test later |
| `FE/lib/screens/home/home_screen.dart` | Modify | 372 lines | Product error rendering manual/widget later |
| `FE/lib/screens/product_list/product_list_screen.dart` | Modify | 479 lines | Error state plus retry |
| `FE/lib/screens/notifications/notifications_screen.dart` | Modify | 108 lines | Stateful load-once behavior test later |
| `FE/lib/blocs/*/*_state.dart` | Read/possibly minor modify | Existing `error` fields | Clear-error semantics if needed |

## Interface Checklist

- [x] `_placeOrder()` checks `items.isEmpty` before dispatch.
- [x] Empty cart and error cart are distinct UI states.
- [x] Empty orders and failed orders load are distinct UI states.
- [x] Home/product list do not label load failures as no products.
- [x] Notifications load only once per screen entry, not every rebuild.
- [x] Retry controls dispatch the same existing load events.

## Dependency Map

```text
Phase 3 UI guard -> Phase 5 widget tests
Phase 3 notification lifecycle -> Phase 5 smoke matrix
Phase 3 avoids DB contract changes -> independent from Phase 4
```

## Implementation Steps

1. Checkout:
   - after resolving `items`, if empty show SnackBar and return.
   - disable button when visible checkout item list is empty if feasible.
2. Cart:
   - if `state.error != null`, show error panel + retry if real user exists.
   - keep empty cart only for successful empty list.
3. Orders:
   - show error + retry when `state.error != null && state.orders.isEmpty`.
   - consider non-blocking snackbar when stale orders exist and refresh fails.
4. Product list/home:
   - render product load error separately from empty list/sections.
   - retry dispatches `LoadProducts`/`ProductLoadFeatured`/categories as needed.
5. Notifications:
   - convert to StatefulWidget.
   - load once with post-frame callback.
   - retry dispatches `NotificationLoad(userId)`.
6. Run `flutter analyze`.

## Test Scenario Matrix

| Scenario | Type | Expected |
|----------|------|----------|
| Checkout opened with no selected items | Widget/manual | Button disabled or SnackBar, no order dispatch |
| Cart service load fails | Widget/manual | Error + retry, not "Giỏ hàng trống" |
| Orders load fails | Widget/manual | Error + retry, not "Chưa có đơn hàng nào" |
| Notifications mark-read rebuild | Widget/manual | Does not reload infinitely |
| Product load fails | Widget/manual | Error message + retry |

## Success Criteria

- [x] Empty checkout cannot call order RPC.
- [x] At least four screens distinguish error from empty state.
- [x] Notifications load is not dispatched from `build`.
- [x] `flutter analyze` passes.

## Risk Assessment

- Risk: adding retries without current user context creates null user errors.
  Mitigation: retry reads `AuthBloc` and disables/shows login prompt when user is
  missing.
- Risk: overbuilding shared error widget. Mitigation: local simple widgets now;
  extract later only if duplication hurts.

## Security Considerations

No new data access. Empty checkout guard is UX; server-side `create_order`
empty-item guard remains required.
