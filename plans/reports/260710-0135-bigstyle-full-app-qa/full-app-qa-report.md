---
title: BigStyle Full-App Runtime QA
date: 2026-07-10
branch: dev
commit: e24713c
environment: Android Emulator API 35, remote Supabase
status: completed_with_findings
---

# Full-App QA Report

## Scope and Result

Build and static checks passed before runtime QA:

| Check | Result |
|---|---|
| `flutter analyze` | Pass, no issues |
| `flutter test --coverage` | Pass, 20/20 tests |
| `flutter build apk --debug` | Pass |
| Admin runtime smoke | Pass with provider limitation |
| Manager runtime smoke | Pass with 3 findings |
| Customer runtime smoke | Pass with 2 findings |

Tested an APK built from `dev` at `e24713c` against the configured remote Supabase project. No application crash or unhandled error screen occurred in the exercised flows.

## Verified Flows

### Admin

- Dashboard loaded remote counts and normalized revenue: [dashboard](screenshots/01-admin-dashboard.png).
- User list, search, role filtering, category list and profile rendered correctly: [users](screenshots/02-admin-users.png), [categories](screenshots/06-admin-categories.png), [profile](screenshots/07-admin-profile.png).
- Add-user client validation rejected an empty submission: [validation](screenshots/05-admin-add-validation.png).
- A successful invite email was not sent in this run because the configured Supabase/Resend testing-recipient policy does not permit arbitrary recipient delivery. Existing error/validation behavior was smoke-tested; production mail delivery remains an external-provider acceptance test.

### Manager

- Dashboard, product list, category manager and voucher manager loaded remote data: [dashboard](screenshots/08-manager-dashboard.png), [products](screenshots/09-manager-products.png), [categories](screenshots/19-manager-categories.png), [vouchers](screenshots/20-manager-vouchers.png).
- Product edit preserved real variant colors after a no-op update through the remote RPC. The product retained 7 variants, total stock 86, and the original `#FFF8DC` / `#8B4513` color values: [edit](screenshots/10-manager-product-edit.png), [variants](screenshots/11-manager-product-variants.png), [result](screenshots/12-manager-product-update-result.png).
- Create-product validation rejected missing required fields without creating a product: [validation](screenshots/14-manager-create-validation.png).
- Order-status update succeeded remotely (`pending -> confirmed`) and showed feedback in the UI: [status result](screenshots/18-manager-order-confirmed.png). The order was restored to `pending` after testing.

### Customer

- Home, product browse/search, product detail, color/size selection and add-to-cart worked: [home](screenshots/21-customer-home.png), [detail](screenshots/22-customer-product-detail.png), [cart add](screenshots/23-customer-add-cart.png).
- Cart selection and checkout loaded correct line items, totals and payment choices: [cart](screenshots/25-customer-cart-selected.png), [checkout](screenshots/26-customer-checkout.png).
- Empty selection is guarded in the cart UI; checkout is not reachable as an actionable purchase until a product is selected.
- Bank-transfer checkout created a pending SePay order and rendered its QR/payment reference. Manual payment polling correctly remained pending when no real transfer was made: [QR](screenshots/30-customer-sepay-qr.png), [pending response](screenshots/31-customer-payment-pending.png).
- The cart remaining intact for a pending bank transfer is intentional: `CheckoutBloc` only clears it once payment confirmation succeeds. The temporary order, its items/payment records, cart item and generated notifications were deleted after QA; affected variant stock was restored to its baseline.
- Notifications, customer order list/detail, profile, empty favorites, and chat entry rendered: [notifications](screenshots/33-customer-notifications.png), [orders](screenshots/42-customer-orders.png), [order detail](screenshots/43-customer-order-detail.png), [profile](screenshots/37-customer-profile.png), [chat](screenshots/39-customer-chat.png).
- Product search submits on the keyboard action, not per keystroke; after submit it returned only the matching product: [submitted search](screenshots/36-customer-explore-submitted.png).

## Findings

### High: Native Google map has a blank viewport

**Observed:** The Store/Delivery screen renders the surrounding shop card but its entire map viewport remains blank after an additional 10-second wait. There are no Google tiles, markers, or route polyline: [after wait](screenshots/41-customer-store-map-after-wait.png).

**Verified cause:** [`FE/android/app/src/main/AndroidManifest.xml`](../../../FE/android/app/src/main/AndroidManifest.xml) has no `com.google.android.geo.API_KEY` metadata. [`AppConfig.googleMapsApiKey`](../../../FE/lib/config/app_config.dart) reads a dotenv value only for the Directions REST request; it does not configure the native `google_maps_flutter` Android SDK. The route fallback still computes 0.5 km, explaining the visible shop card despite the absent map.

**Required fix:** Provision a restricted Android Maps SDK key through a build-time manifest placeholder or secure Android resource, enable Maps SDK for Android in Google Cloud, and verify on an emulator/device after reinstall. Do not commit the raw key.

### Medium: Manager cannot identify a known customer in order detail

**Observed:** For an order belonging to the existing profile `Trần Thị Demo`, manager detail displays `Khách hàng: Không rõ`: [evidence](screenshots/16-manager-order-detail.png).

**Code path:** [`OrderModel.fromMap`](../../../FE/lib/models/order_model.dart) only derives `customerName` from a joined `customer.full_name` or `shipping_address.name`; [`ManagerOrderDetailScreen`](../../../FE/lib/screens/manager/manager_order_detail_screen.dart) then falls back to `Không rõ`. The live manager-order payload did not provide either value.

**Required fix:** Make the manager order query/RPC return a reliable customer name and cover an order whose shipping address has no `name` property with a regression test.

### Medium: Manager dashboard does not refresh after an order status update

**Observed:** After confirming an order, the Orders tab updated, but navigating back to Dashboard still showed its old `Chờ xác nhận` card during the same session.

**Cause:** [`ManagerBloc._onUpdateOrderStatus`](../../../FE/lib/blocs/manager/manager_bloc.dart) refreshes `orders` only; it leaves `recentOrders` and `dashboardStats` untouched. [`ManagerDashboard`](../../../FE/lib/screens/manager/manager_dashboard.dart) reloads only in `initState` or pull-to-refresh, while `ManagerShell` keeps it alive in an `IndexedStack`.

**Required fix:** Reload dashboard data after a successful status update, or derive/update the affected recent-order entry in the bloc. Include a bloc/widget regression test.

### Low: Favorites highlights the Orders navigation tab

**Observed:** The screen title is `Yêu thích`, but the bottom navigation highlights `Đơn hàng`: [evidence](screenshots/38-customer-favorites.png).

**Cause:** [`FavoritesScreen`](../../../FE/lib/screens/favorites/favorites_screen.dart) constructs `AppBottomNav(currentIndex: 3)`, which is the Orders tab.

**Required fix:** Decide the intended navigation model for Favorites, then use the profile index, no bottom navigation, or a dedicated destination. Add a widget test for the selected destination.

### Low: `orders.updated_at` was unchanged by a status mutation

**Observed:** The direct status update succeeded, but the order's `updated_at` remained at its pre-update value. This weakens audit/history semantics even though the UI flow works.

**Required fix:** Add or repair the database `updated_at` trigger for `orders`, then assert it in an integration/database test.

## Test Limitations

- Real SePay settlement could not be completed without an actual bank transfer; pending handling was verified instead.
- Successful invite delivery needs a recipient allowed by the deployed mail provider policy.
- Voucher error runtime entry was not conclusive because emulator text automation focused the address field; the checkout voucher validation unit/widget coverage passed.
- The address `23%20Test%20Street` shown in the seeded order detail is pre-existing test data encoded by an earlier automation input, not an app-generated URL encoding verdict from this run.

## Cleanup Verification

- QA-created SePay order, order items, payment record, cart item, and manager-status notifications: deleted.
- Manager QA order restored from `confirmed` to `pending`.
- Tested product variant stock restored to 10.
- No product, user, or voucher was created by this run.

## Recommended Next Work

1. Fix and smoke-test Android Google Maps configuration first; it is visibly broken for customers.
2. Fix the manager order payload and post-status dashboard refresh together, then add focused bloc/widget tests.
3. Correct Favorites navigation state and add a visual/widget regression test.
4. Restore `orders.updated_at` maintenance in the database migration layer.

## Unresolved Questions

- Which Google Cloud project/key and Android package/SHA restrictions should be used for the Maps SDK deployment?
- Should Favorites be a profile subpage without persistent bottom navigation, or be promoted to a dedicated navigation destination?
