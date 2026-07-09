# BigStyle Remote Data Android Smoke Report

Date: 2026-07-09
Project: `bigstyle-prm393` / `agbnpqgxsppdrpbqoipo`
Device: Android emulator `pixel8` / `emulator-5554`

## Summary

Remote data hardening and Android smoke passed for the critical manager and
customer flows.

## Remote Changes

- Applied RPC migration `update_product_with_variants_rpc`.
- Applied grant repair `restrict_update_product_with_variants_rpc_execute`.
- Verified `update_product_with_variants`:
  `SECURITY DEFINER`, `search_path=public`, `anon_can_execute=false`,
  `authenticated_can_execute=true`.
- Assigned 15 orphan seed products to
  `hoangbavan4478+manager@gmail.com`.
- Enabled repeatable QA login for existing related manager/customer accounts by
  setting password hashes in Supabase Auth.
- Repaired 2 image URLs returning HTTP 404. Second HEAD sweep returned 200 for
  all active seed image URLs.

## App Changes

- Added debug-only password login via `--dart-define` values.
- Debug buttons are hidden in release mode and hidden in debug unless
  credentials are provided at runtime.
- Removed a remote SVG image from the Google login button because Flutter
  Android cannot decode SVG through `Image.network`.
- Hardened local RPC migration grants so future resets do not leave the RPC
  executable by `anon`.

## Verification

- `flutter analyze`: pass.
- `flutter test`: pass, 3/3 tests.
- Manager flow:
  - Dedicated manager login worked.
  - Dashboard showed 15 products.
  - Product tab showed `Tổng: 15` and `Hiển thị 15 trên 15 sản phẩm`.
  - Product edit form loaded existing images, colors, category, name, and price.
  - RPC update path verified in a rollback SQL transaction.
- Customer flow:
  - Dedicated customer login worked.
  - Home, categories, featured products, and detail page rendered.
  - Add-to-cart created one cart item.
  - Cart selected checkout enabled `Mua hàng (1 sản phẩm)`.
  - COD checkout created order `CF-20260709-54E569`.
  - Cart cleared after checkout.
  - Order detail displayed the new order.

## Evidence Screenshots

Saved under `reports/android-smoke-screens/`:

- `01-manager-dashboard.png`
- `02-manager-test-dashboard.png`
- `03-manager-products.png`
- `04-manager-product-edit.png`
- `06-customer-home.png`
- `07-customer-product-detail.png`
- `09-customer-cart.png`
- `10-customer-cart-selected.png`
- `11-customer-checkout.png`
- `12-customer-place-order-result.png`
- `13-customer-orders.png`

## Notes

- The first manager product-tab attempt showed 0 products because the emulator
  still had the older `hoangbavan4478@gmail.com` session. After logging out and
  using the dedicated `+manager` account, the product tab showed 15 products.
- Product save was not performed from UI to avoid mutating demo data without
  explicit approval. The RPC was verified through a rollback transaction.
- Address text entered via `adb shell input text` kept encoded spaces in the
  created test order. This is a test-input artifact, not a checkout blocker.
- Remaining runtime warnings were emulator frame/IME jank and Android
  back-dispatcher warnings.

## Unresolved Questions

None.
