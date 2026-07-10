# Phase 4 Gap Findings — Manager (rubric-v1)

Vision model: gemini-2.5-flash, batch of 8. Screenshots: `docs/audit-assets/overhaul/manager/`.

## ManagerProductList (`01`, code: `FE/lib/screens/manager/products/manager_product_list_screen.dart`)

| Type | Sev | Finding |
|---|---|---|
| status-badge | L | "Đang bán" success badge is solid-fill green + white text — violates v2 tonal-badge rule |
| color | L | FAB, selected nav, badges on v1 pink `#C4517A`; background not yet `#FBF6EF` |
| typography | L | Headings/body on Playfair Display/DM Sans, not Cormorant/Montserrat |
| shape | M | Card/input/chip radii on v1 scale (16/12/20), not v2 (20/14/24) |
| contrast | M | Search placeholder "Tìm kiếm sản phẩm..." low-contrast on white |
| touch-target | M | Product-card nav arrow appears under 48dp |

## ManagerProductDetail (`02`, code: `FE/lib/screens/manager/products/manager_product_detail_screen.dart`)

| Type | Sev | Finding |
|---|---|---|
| color | L | AppBar, "Cập nhật" button, "Chọn tập tin" link on v1 pink; page background white not `#FBF6EF` — **confirms phase-02 finding #3**: M19 (AppBar pink→white) fixed on list screen but not here |
| typography | L | Headings/body on v1 fonts |
| shape | L | Section cards, button, inputs below v2 radii |
| status-badge | M | "Ảnh chính" chip solid-fill pink + white text — tonal violation |
| text-clip | S | AppBar title "Chi tiết & Cập nh..." truncated |
| thumb-zone | M | Primary CTA "Cập nhật" sits in top-right AppBar, outside comfortable thumb reach |

## ManagerProfile (`13`, inline `_ManagerProfileScreen` in `manager_shell.dart:55`)

| Type | Sev | Finding |
|---|---|---|
| color | L | AppBar, avatar bg, active bottom-nav on v1 pink |
| typography | L | Heading "Quản lý BigStyle" on Playfair Display |
| typography | L | Body/email/list/nav-label text on DM Sans |
| color | M | Content background pure white, not `#FBF6EF` |
| contrast | M | Inactive bottom-nav icons/text look under-contrast vs white |
| color | S | "Đăng xuất" red is unspecified — swap to `error` `#C0392B` |

## ManagerVoucherList (`18`, code: `FE/lib/screens/manager/vouchers/manager_voucher_list_screen.dart`)

| Type | Sev | Finding |
|---|---|---|
| contrast | L | FAB white-on-`#C4517A` fails AA (2.89:1); **v2 primary `#9A3F35` also fails white-on-fill (3.55:1)** — confirms the tokens-v2 doc's own finding that only `error` passes white-on-fill; FAB icon-only buttons need a darker fill or icon-only (no text) treatment |
| typography | L×2 | AppBar title + body/chip text on v1 fonts |
| color | M | FAB background v1 pink |
| status-badge | M | "Đang bật" badge green-on-light-green may still be under AA — re-check with v2 `success` `#2E6B47` tonal pairing specifically |
| shape | M | Card/FAB/chip radii below v2 scale |

## ManagerCategoryList (`20`, code: `FE/lib/screens/manager/categories/manager_category_list_screen.dart`)

| Type | Sev | Finding |
|---|---|---|
| color | L | FAB solid v1 pink |
| typography | L×2 | AppBar title + body text on v1 fonts |
| status-badge | L | "Hiển thị" chip solid green + white text — tonal violation |
| shape | M | List-item card radius ~16, needs 20 |
| contrast | M | "2 sản phẩm" secondary text borderline AA (~4.38:1, needs 4.5:1) |

## ManagerDashboard (`21`, code: `FE/lib/screens/manager/manager_dashboard.dart`)

| Type | Sev | Finding |
|---|---|---|
| color | L | Active tab/icons on v1 pink |
| typography | L | Headings + body on v1 fonts |
| status-badge | L | "Chờ xác nhận" (orange) / "Đã xác nhận" (pink) badges solid-fill + white text — **this is `ux-flow-audit.md` M6**, confirmed still open and visible |
| contrast | L | "Doanh thu hôm nay" label + "0 đ" value both read low-contrast |
| shape | M | Stat cards + chips below v2 radii |
| color | M | Green/orange icon colors don't map to v2 `success`/`warning` tokens |

## ManagerOrders (`22`, code: `FE/lib/screens/manager/manager_orders_screen.dart`)

| Type | Sev | Finding |
|---|---|---|
| status-badge | L | "Chờ xác nhận"/"Đã xác nhận"/"Hoàn thành" all solid-fill + white text, "Chờ xác nhận" (yellow+white) especially poor contrast — same M6-class issue as ManagerDashboard, now confirmed on the Orders list too |
| color | L | Selected tab, indicator, "Đổi trạng thái" button on v1 pink |
| typography | L | Full v1 font usage |
| shape | M×2 | Status chips + order cards below v2 radii |
| contrast | M | "Chờ xác nhận" yellow-bg/white-text fails WCAG outright |

## ManagerOrderDetail (`26`, code: `FE/lib/screens/manager/manager_order_detail_screen.dart`)

| Type | Sev | Finding |
|---|---|---|
| color | L | "Cập nhật trạng thái" button + price text on v1 pink |
| typography | L | Full v1 font usage |
| status-badge | L | "Chờ xác nhận" chip solid yellow + white — same class as above |
| shape | M | Card/button/chip radii below v2 scale |
| contrast | M×2 | Update button (3.01:1) and status chip both fail AA |

## Cross-Screen Pattern (dedup candidate for consolidation)

**Status-badge tonal violation appears on 6/8 manager screens** (ProductList, ProductDetail, VoucherList, CategoryList, Dashboard, Orders, OrderDetail — 7 actually) — this is the single highest-leverage fix in the manager surface: one new shared `StatusBadge` component (tonal, using v2 `success`/`warning`/`error`) replaces ~7 bespoke solid-fill implementations. Directly implements the `docs/design-tokens-v2.md` status-badge rule and closes `ux-flow-audit.md` M6.

**Color/typography full-sweep needed on all 8/8** — expected, matches Phase 1's 100%-bespoke, 0-shared-widget finding for the entire manager surface.

## Screen Verdict

All 8 manager screens: **real findings**, none are token-swap-only — matches Phase 1's T3/T2 tier prediction (manager screens dominate the T3 tier).
