# Test Report — 2026-07-10 — Full-App Emulator Audit (post visual-reskin merge)

Scope: `dev` @ `fab9a26` (visual-reskin merged). Pixel 8 AVD (emulator-5554), API 35, remote Supabase (`bigstyle-prm393`). All 3 roles + guest walked live via `flutter run` + `adb`/`uiautomator`, watching console for exceptions throughout.

## Test Results Overview
- `flutter analyze`: 0 issues
- `flutter test`: 43/43 pass
- Runtime exceptions caught in console: 1 (Hero tag collision, see Critical Issues)
- Roles covered: Admin (full), Manager (full), Customer (partial: home/product-detail/cart), Guest/Auth (full)

## Critical Issues

### 1. [High] Prices render with no thousands-separator across nearly the whole customer funnel
**Not reskin-related** — pure formatting logic, pre-existing.
`'${price.toStringAsFixed(0)}đ'` (no `NumberFormat`) is used in 12 files / 16 call sites: `widgets/product_card.dart:140,148` (home, search, every product list), `product_detail/product_detail_screen.dart:167,369,375`, `blocs/product_detail/product_detail_state.dart:25,30`, `cart/cart_screen.dart:224,334`, `cart/cart_item_edit_screen.dart:217`, `checkout/checkout_screen.dart:478`, `checkout/widgets/checkout_price_summary.dart:65`, `checkout/widgets/checkout_item_list.dart:57`, `orders/orders_screen.dart:135`, `orders/order_detail_screen.dart:132,328`, `delivery/delivery_map_screen.dart:504`.
Only 2 files format correctly with `NumberFormat('#,###','vi_VN')`: `manager/products/manager_product_list_screen.dart`, `manager/manager_order_card.dart` (both manager-side).
**Impact:** any item ≥ 1.000đ (i.e. almost all real inventory) renders as an unbroken digit string, e.g. a 350.000đ dress shows `350000đ` — confirmed live on Home, Product Detail, Cart (screenshots 17-19, all show `10000đ`).
**Fix:** extract the manager side's `NumberFormat('#,###','vi_VN')` call into a shared helper (e.g. alongside `formatOrderCurrency` in `models/order_model.dart`, which manager already uses) and replace all 16 call sites.

### 2. [High] Hero tag collision — multiple FloatingActionButtons share Flutter's default hero tag
**Not reskin-related** — pre-existing structural issue, confirmed live via console:
```
EXCEPTION CAUGHT BY SCHEDULER LIBRARY
There are multiple heroes that share the same tag within a subtree.
... multiple heroes had the following tag: <default FloatingActionButton tag>
```
**Confirmed root cause:** `screens/admin/admin_shell.dart` mounts all 4 admin tabs simultaneously via `IndexedStack` (line 21-26). `admin_users_screen.dart:26` and `admin_categories_screen.dart:26` each declare `FloatingActionButton.extended(...)` with no `heroTag`. Both are alive in the same subtree → Flutter's `HeroController` finds 2 heroes with the same default tag the moment `AdminShell` is pushed (fires once, at login redirect; confirmed via log — exactly 1 occurrence, and it did not recur across 6+ tab switches since `IndexedStack` index changes don't re-trigger Hero scans).
**Currently silent** (caught by the scheduler, no visible crash in the runs done here) but fragile — same pattern.
**Related unconfirmed risk (Manager):** `manager_shell.dart`'s `IndexedStack` itself only holds one FAB-bearing tab at a time, but `ManagerVoucherListScreen` and `ManagerCategoryListScreen` (both with their own un-tagged FABs) are reached via `Navigator.push` while `ManagerProductListScreen`'s FAB stays alive underneath in the `IndexedStack`. A real `PageRoute` push transition **does** run Hero flights (unlike `IndexedStack` switches), so this path is more likely to visibly glitch. Not runtime-verified this session (would require pushing into Voucher/Category management as manager).
**Fix:** give every `FloatingActionButton` in `admin_users_screen.dart`, `admin_categories_screen.dart`, `manager_product_list_screen.dart`, `manager_voucher_list_screen.dart`, `manager_category_list_screen.dart` a unique `heroTag` (or `heroTag: null` — none of these appear to want a hero-morph animation).

## Findings

### Medium: Manager dashboard stat cards use different typography/color tokens than Admin's identical pattern
**Reskin-phase inconsistency** (Phase 5 vs Phase 6 picked different tokens for the same widget shape).
- Admin `_StatCard` (`admin_dashboard_screen.dart:342-357`): value = plain bold `TextStyle(fontSize:22, fontWeight:w700, color: AppColors.textPrimary)`; label = `color: AppColors.textSecondary`.
- Manager `_StatCard` (`manager_dashboard_widgets.dart:96-104,88-91`): value = `AppTypography.displaySmall.copyWith(color: color)` → serif Cormorant, w600, tinted to the card's accent color instead of `textPrimary`; label = `AppTypography.caption` → `AppColors.textHint` (the palette's lowest-contrast tone, meant for input placeholders).
Confirmed live (screenshot 12): Manager's stat numbers look thin/serif/tinted and labels look washed-out next to Admin's bold black sans-serif numbers and legible gray labels for the exact same UI pattern.
**Fix:** make Manager's `_StatCard` match Admin's (plain bold `textPrimary` value, `textSecondary` label), or intentionally redesign both together — but they should match.

### Low: Manager's product-list header badge says "Quản trị" (Admin/Administration), not manager-appropriate copy
**Not reskin-related** — hardcoded string, pre-existing.
`manager/products/manager_product_list_screen.dart:53,71` hardcodes `'Quản trị BigStyle'` + a `'Quản trị'` badge, unconditionally, regardless of actual signed-in role. Confirmed live (screenshot 13) while signed in as the Manager test account (whose own admin-panel user record is labeled "Quản lý" = Manager). Cosmetic/copy-only, no functional impact, but misleading terminology directly contradicts the app's own role model.

### Low: AppBar treatment is structurally inconsistent between and within shells
Admin's Dashboard/Users/Categories/Profile all use a custom gradient `Container` header (`[AppColors.primary, AppColors.primaryDark]`, white text). Manager's Dashboard/Products/Orders use a plain `AppBar(backgroundColor: AppColors.surface)` (light, default-black text) — but Manager's own Profile tab switches back to the gradient-header style. Confirmed via code + screenshots 6/7/12/13/14/15. Likely pre-existing (reskin scope was token substitution in place, not restructuring), but worth a deliberate design decision rather than leaving it scattered.

### Low: Admin profile header email wraps awkwardly
`hoangbavan4478+admin@gmail.com` wraps to a second line with just `m` on its own line (screenshot 7). Minor, long-string layout edge case, likely pre-existing.

## What Was Verified Clean
- Cormorant serif renders correctly with full Vietnamese diacritics (`PHONG CÁCH`, `RIÊNG CỦA BẠN`) — closes a gap the reskin journal had flagged as visually unverified.
- Debug test-login buttons correctly hidden with no `--dart-define` creds, correctly shown once supplied (matches `FE/README.md` contract).
- Client-side validation: Admin add-user (empty submit → "Email không hợp lệ", no user created), OTP email field (malformed input → same message, no network call).
- Admin Users filter chips (Tất cả/Khách hàng/Quản lý/Admin) correctly scope the list; chip tonal-selected styling matches the reskin's `ChipThemeData` work.
- Manager Orders: customer-name denormalization fix still resolves real names ("Trần Thị Demo"), status badges render correct tones (warning/info/success) — prior session's fixes hold post-merge.
- Cart subtotal correctly excludes unchecked items (by design, not a bug).
- Logout works cleanly for both Admin and Manager, returning to the login screen with no residual state.
- 0 new exceptions introduced by any navigation performed this session beyond the one pre-existing Hero collision.

## Test Limitations
- Customer role only covered Home / Product Detail / Cart — did not reach Checkout, Orders, Favorites, Profile, Chat, or Notifications this pass (time-boxed; those were previously verified in the 260710-0135 QA sweep and are lower-risk for a token-only reskin).
- Manager-side Hero collision (Voucher/Category push transitions) is a code-level risk assessment, not a runtime-confirmed repro.
- Two seeded Supabase auth accounts (`hoangbavan4478+manager@gmail.com`, `hoangbavan4478+customer2@gmail.com`) had their passwords reset to a known value (`BigStyleQA2026!`) via direct `auth.users` update, at your explicit direction ("check on Supabase"), to reach the debug test-login flow — same mechanism used in the prior QA-fix session. Rotate again if you want these locked back down.

## Recommendations
1. **High** — Centralize currency formatting (reuse `formatOrderCurrency`/`NumberFormat('#,###','vi_VN')`) across the 16 unformatted call sites; this is customer-facing on every screen that shows a price.
2. **High** — Add explicit unique `heroTag`s to all 5 un-tagged FABs (2 admin, 3 manager).
3. **Medium** — Align Manager's dashboard `_StatCard` typography/color with Admin's.
4. **Low** — Replace the hardcoded "Quản trị" badge with role-aware copy, or a fixed neutral label if it's meant to be generic.
5. **Low** — Decide on one AppBar treatment per shell (or per screen-type) and apply consistently.

## Unresolved Questions
- Is the Admin-gradient vs Manager-plain AppBar split intentional (distinct role identity) or an oversight? Affects whether finding 3 (AppBar) is a "fix" or a "leave as-is."
- Do you want the Manager-side Hero-collision risk (Voucher/Category push) runtime-verified before fixing, or is the Admin repro sufficient to justify fixing all 5 FABs now?
