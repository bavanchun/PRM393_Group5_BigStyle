---
phase: 6
title: "Checkout Modularization"
status: pending
priority: P2
effort: "1d"
dependencies: [4]
---

# Phase 6: Checkout Modularization

## Overview

Split the 758-line checkout screen into focused sections while preserving the
verified customer checkout behavior: selected cart items, address form, payment
method, voucher/total preview, COD order, SePay QR navigation, and cart clear.

## Requirements

- Functional: customer checkout smoke remains pass.
- Functional: empty selected items guard remains early and visible.
- Functional: COD and bank transfer paths preserve current arguments/contracts.
- Non-functional: smaller widgets with stable dimensions and no text overflow.

## Architecture

Keep `CheckoutBloc`, `CheckoutEvent`, `CheckoutState`, `PaymentService`, and
`OrderService.createOrderViaRpc()` contracts unchanged.

Target extraction:

- `checkout_address_form.dart`
- `checkout_item_list.dart`
- `checkout_payment_method_selector.dart`
- `checkout_price_summary.dart`
- `checkout_voucher_field.dart`
- optional `checkout_submit_bar.dart`

Parent `CheckoutScreen` remains the coordinator for route args, selected item
collection, BLoC listeners, and navigation to `/payment-qr`.

## File Inventory

| Path | Action | Test impact |
|---|---|---|
| `FE/lib/screens/checkout/checkout_screen.dart` | Modify | Reduce coordinator size. |
| `FE/lib/screens/checkout/widgets/*.dart` | Create | Section-level widget tests. |
| `FE/test/widgets/checkout_*_test.dart` | Create | Guard price/payment UI behavior. |
| `FE/lib/blocs/checkout/*` | Read/modify only if needed | Contract tests from Phase 4 should protect. |

## Tests Before

- Add widget test for empty selected items / disabled submit behavior if feasible.
- Add widget test for payment method selector preserving `cod` and `bank_transfer` values.
- Add price summary test for subtotal/shipping/discount/total display.

## Implementation Steps

1. Freeze current route args and `_placeOrder()` behavior with tests.
2. Extract read-only visual sections first.
3. Extract payment selector with value/callback.
4. Extract address form with controllers still owned by parent screen.
5. Extract voucher/price summary.
6. Keep navigation side effects in parent screen.
7. Run customer smoke after extraction:
   home -> product -> cart -> checkout -> COD -> orders.

## Test Scenario Matrix

| Scenario | Priority | Expected |
|---|---|---|
| Empty selected items | Critical | No checkout dispatch. |
| COD submit success | Critical | Order created and selected cart items cleared. |
| Bank transfer submit | Critical | Navigates to QR with order args. |
| Payment selector | High | Emits exact string values. |
| Price summary | High | Total math displayed consistently. |
| Voucher field | Medium | Existing validation path preserved. |

## Refactor

- No new checkout business rules in this phase.
- Do not move money calculation into UI widgets; widgets render values only.
- Keep parent screen responsible for BLoC side effects.

## Tests After

- Full test suite.
- Android customer checkout smoke.

## Regression Gate

```bash
cd FE
flutter analyze
flutter test
```

## Success Criteria

- [ ] Checkout screen reduced and readable.
- [ ] Extracted widgets have focused tests.
- [ ] Existing COD and SePay flows still work.
- [ ] Empty selected items guard remains.
- [ ] No route arg contract changed.

## Risk Assessment

- Risk: controller ownership bug after extraction. Mitigation: parent owns all
  controllers; children receive controllers/callbacks.
- Risk: payment args drift breaks QR screen. Mitigation: test route arg map or
  keep navigation code in parent.

## Security Considerations

- Client total remains preview; authoritative total remains RPC.
- Do not trust voucher/price data from UI widgets.

## Dependency Map

Depends on Phase 4 tests. Independent from Phase 5 after coverage is in place.
