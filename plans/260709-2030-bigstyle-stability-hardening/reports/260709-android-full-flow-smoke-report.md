# Test Report - 260709 - Android Full Flow Smoke

## Test Results Overview
- **Scope**: Flutter Android emulator smoke for login, manager dashboard, products, orders, categories, vouchers, profile.
- **Device**: `pixel8` / `emulator-5554`
- **Code checks**: `flutter analyze` PASS, `flutter test` PASS 3/3.
- **Runtime**: App built, installed, launched, Supabase initialized.

## Build / Config Status
- **PASS**: `flutter analyze`
- **PASS**: `flutter test`
- **FIXED DURING TEST**: Android build initially loaded empty Supabase URL/key because `.env` was not declared as Flutter asset. Added `.env` under `flutter.assets` in `FE/pubspec.yaml`.
- **Verified after fix**: App no longer throws `No host specified in URI /auth/v1/otp?`.

## UI Test Results
- **Screenshots**: `./android-full-flow-screens/`
- **Login screen**: PASS
- **Empty email validation**: PASS, shows `Vui lòng nhập email`.
- **Invalid email validation**: PASS, shows `Email không hợp lệ`.
- **Google Sign-In entry**: PASS, account picker opens. Personal-account picker screenshot removed from report.
- **Manager dashboard**: PASS, shows remote stats: 15 products, 2 pending orders, recent orders.
- **Manager products tab**: FAIL/DATA BLOCKER, dashboard says 15 products but products tab shows `Tổng: 0` and empty list.
- **Create product form**: PASS open/navigation. Empty save validation PASS for missing name and invalid price. No product created.
- **Manager orders tab**: PASS, 6 remote orders render with filters/actions.
- **Manager order detail**: PASS, order item, totals, payment and address render.
- **Order status sheet**: PASS, warning for unpaid bank transfer order render, options show. No status mutation performed.
- **Manager categories**: PASS, 5 categories render with product counts.
- **Manager vouchers**: PASS, 2 vouchers render.
- **Manager profile/edit profile**: PASS open/navigation. Screenshots removed due personal info.

## Critical Issues
1. **Manager product list cannot see seed products**
   - Remote has 15 products, but all have `store_id = null`.
   - Manager RLS/listing expects products owned by current manager, so tab product list is empty.
   - Impact: manager cannot edit existing seed products from UI.

2. **Remote still lacks product update RPC**
   - Local app calls `update_product_with_variants`.
   - Remote migration list did not include the new RPC migration during Supabase check.
   - Impact: manager product edit will fail once product ownership is fixed unless migration is applied.

3. **Customer flow not fully verified**
   - Current live session is manager account.
   - Gmail search found no Supabase/OTP email newer than 1 day.
   - Google account selection requires explicit approval because it uses a personal account.
   - Impact: customer cart/checkout/orders/wishlist/profile were not end-to-end verified in this run.

4. **Runtime image 404**
   - Flutter logged `NetworkImageLoadException` for `https://images.unsplash.com/photo-1594938298603-c8148c4b1947?w=400`.
   - Impact: at least one product image URL is broken and may show fallback/error.

## Non-Blocking Runtime Warnings
- Emulator used software GL due memory pressure; several skipped-frame/jank warnings observed.
- Android warns `OnBackInvokedCallback` not enabled.
- Earlier Google/SVG image decoder warning still appears on login Google button asset path.

## Recommendations
1. Apply remote migration for `update_product_with_variants`.
2. Assign seed products `store_id` to the manager user intended to own catalog, or adjust seed/RLS model.
3. Provide/confirm a dedicated customer test account flow so cart/checkout/orders can be tested without personal Google account ambiguity.
4. Replace broken Unsplash image URLs with stable Supabase Storage/product image URLs.
5. Add a small integration smoke path or debug-only test login route for demo QA, guarded from release builds.

## Unresolved Questions
- Which account should own the 15 seed products: `hoangbavan4478@gmail.com` or `hoangbavan4478+manager@gmail.com`?
- Should I select the personal Google account in emulator for future auth testing, or should we create a dedicated test Google/customer account?
