# Checkout Modularization

Date: 2026-07-10
Branch: `dev`

## Summary

Split checkout visual sections into focused widgets while keeping route args,
selected item filtering, BLoC listener side effects, and `_placeOrder()` in the
parent screen.

## Code Changes

- `FE/lib/screens/checkout/widgets/checkout_address_section.dart`
  - Renders address input, current-location action, and coordinate confirmation.
- `FE/lib/screens/checkout/widgets/checkout_item_list.dart`
  - Renders selected cart item rows.
- `FE/lib/screens/checkout/widgets/checkout_payment_method_selector.dart`
  - Emits exact existing values: `cod` and `bank_transfer`.
- `FE/lib/screens/checkout/widgets/checkout_voucher_field.dart`
  - Renders voucher input, error text, and apply action.
  - Widened the apply button to prevent a real widget-test overflow.
- `FE/lib/screens/checkout/widgets/checkout_price_summary.dart`
  - Renders subtotal, shipping, optional discount, and total.
- `FE/lib/screens/checkout/checkout_screen.dart`
  - Reduced to checkout coordination and side effects.

## Size Change

| File | Before | After |
|---|---:|---:|
| `checkout_screen.dart` | 758 | 532 |
| `checkout_address_section.dart` | 0 | 85 |
| `checkout_item_list.dart` | 0 | 66 |
| `checkout_payment_method_selector.dart` | 0 | 101 |
| `checkout_price_summary.dart` | 0 | 76 |
| `checkout_voucher_field.dart` | 0 | 51 |

## Added Coverage

- `FE/test/widgets/checkout_sections_test.dart`
  - Payment selector emits `bank_transfer` and `cod` exactly.
  - Price summary displays subtotal, shipping, discount, and total.
  - Voucher field preserves input/error and calls apply callback.

## Verification

- `cd FE && flutter analyze`: PASS, no issues.
- `cd FE && flutter test`: PASS, 20 tests.

## Notes

Customer runtime smoke is left for the final verification phase because this
phase intentionally avoided changing route/navigation side effects.

## Unresolved Questions

None.
