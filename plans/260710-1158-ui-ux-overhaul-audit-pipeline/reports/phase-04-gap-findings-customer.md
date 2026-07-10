# Phase 4 Gap Findings — Customer (rubric-v1)

Vision model: gemini-2.5-flash, 2 batches (8+6). Screenshots: `docs/audit-assets/overhaul/customer/`. All frames from the seeded demo customer account (no PII redaction needed per phase-02 policy check) — one Gemini finding on the Profile screen quoted the demo account's on-screen QA-alias email verbatim; that text is **omitted** below per plan.md hygiene policy (committed docs must not contain account emails), described instead as "account email".

## Chat (`07`, code: `FE/lib/screens/chat/chat_screen.dart`)

| Type | Sev | Finding |
|---|---|---|
| color | L | Avatar bg, quick-reply chips, send button on v1 pink `#C4517A` |
| typography | L | Full v1 font usage |
| contrast | L | White text on v1 primary (avatar initials, chip text) is 3.1:1, fails AA |
| shape | M×2 | Quick-reply chips (~20dp) and input field (~12dp) below v2 (24/14) |
| contrast | M | Secondary text "Trợ lý thời trang AI" + placeholder under-contrast on white |

## CartItemEdit (`08`, code: `FE/lib/screens/cart/cart_item_edit_screen.dart`)

| Type | Sev | Finding |
|---|---|---|
| color | L | Price, selected size chip "3XL", selected-color checkmark/border on v1 pink |
| typography | L | Full v1 font usage across app bar/product name/price/headings/labels |
| shape | M | Size chips + quantity stepper buttons below v2 (chipRadius 24, buttonRadius 14) |
| status-badge | M | Selected "3XL" chip solid-fill primary + white text — tonal violation |
| color | S | Content background light grey, not `#FBF6EF` |
| touch-target | M | Quantity stepper +/- buttons look under 48dp |

## ProductDetail (`09`, code: `FE/lib/screens/product_detail/product_detail_screen.dart`)

| Type | Sev | Finding |
|---|---|---|
| typography | L | Title on Playfair Display, body on DM Sans |
| color | L | Price, selected size chip, "Mua ngay" CTA on v1 pink |
| contrast | L | Price + "Hướng dẫn chọn size" link **stay under AA even after v2 primary swap** (3.9:1 vs 4.5:1 needed) — needs a darker text color than raw `primary`, not a straight swap |
| contrast | M | White text on solid "L" chip / "Mua ngay" button also under AA both pre- and post-swap — same class as above |
| shape | M | Content card top radius, buttons, chips all below v2 scale |
| touch-target | M | Color-swatch circles look under 48dp |

## ProductList (`12`, code: `FE/lib/screens/product_list/product_list_screen.dart`)

| Type | Sev | Finding |
|---|---|---|
| color | L | Active filter chip + active bottom-nav on v1 pink |
| typography | L×2 | Headings + body/chips/prices/nav-labels on v1 fonts |
| shape | M×2 | Product cards (~16dp) + filter chips (~12-16dp) below v2 (20/24) |
| status-badge | M | Active "Tất cả" filter chip solid pink + white text — tonal violation |
| contrast | M | Size labels + inactive filter-chip text light-grey-on-white, likely under AA |
| text-clip | M | Product title truncated mid-word, VN diacritics affected |

## Home (`15`, code: `FE/lib/screens/home/home_screen.dart`)

| Type | Sev | Finding |
|---|---|---|
| color | L | Logo, banner, active bottom-nav, "Xem tất cả" link all v1 pink |
| typography | L | Full v1 font usage |
| shape | M | Banner/product cards (~16dp→20) and category cards (~20dp→24) below v2 |
| color | M | Background white not `#FBF6EF`; category-card tint should map to `secondary` `#E8C9A0` |
| touch-target | M | Bell + avatar icons in top bar look under 48dp |
| color | S | Headings need `textPrimary`, placeholder needs `textSecondary` |

## DeliveryMap (`16`, code: `FE/lib/screens/delivery/delivery_map_screen.dart`)

| Type | Sev | Finding |
|---|---|---|
| color | L | "Chỉ đường" CTA on v1 pink |
| typography | L | Full v1 font usage |
| shape | M | Bottom sheet corners ~16-20px, needs `bottomSheetRadius` 28 |
| status-badge | M | "0.5 km" chip solid-ish pink — needs tonal style + `chipRadius` 24 |
| color | S | Background white not `#FBF6EF` |
| contrast | M | Address/time/fee text under-contrast — verify against `textSecondary`/`surface` pairing |

## EditProfile (`17`, code: `FE/lib/screens/profile/edit_profile_screen.dart`)

| Type | Sev | Finding |
|---|---|---|
| status-badge | L | "Khách hàng" chip solid green + white text — tonal violation |
| color | M | "Lưu thay đổi" button on v1 pink |
| touch-target | M | Profile-picture camera icon looks under 48dp |
| typography | M×2 | AppBar title + body/labels on v1 fonts |
| shape | M | Inputs + save button at v1 12dp, need v2 14dp |

## Cart (`23`, 2 states: default/empty + filled)

| Type | Sev | Finding |
|---|---|---|
| color | L | CTA, active bottom-nav, price all v1 pink (both states) |
| color | L | Background light pink tint, not `#FBF6EF` (both states) |
| typography | L×2 | AppBar title + body/button/nav-label text on v1 fonts (both states) |
| shape | M×2 | Cart-item card ~16dp, quantity/CTA buttons ~12dp — below v2 (20/14) (filled state) |
| touch-target | M | Quantity buttons + trash icon look under 48dp (filled state) |
| contrast | M | Secondary empty-state text + inactive nav under-contrast (empty state) |

## Orders (`24`, code: `FE/lib/screens/orders/orders_screen.dart`)

| Type | Sev | Finding |
|---|---|---|
| status-badge | L | "Đã xác nhận" badge solid pink + white text — tonal violation |
| color | M | Prices + active bottom-nav on v1 pink |
| typography | M | AppBar + body on v1 fonts |
| shape | S×2 | Order cards (~16dp→20) + status chips (~20dp→24) below v2 |
| touch-target | M | AppBar back-arrow looks under 48dp |

## OrderDetail (`25`, 2 states: loading + default)

| Type | Sev | Finding |
|---|---|---|
| color | L | Status dot, "Chờ xác nhận" chip, "Tổng cộng" text, "Quay lại" border all v1 pink; "Hủy đơn hàng" red needs `error` `#C0392B` |
| typography | L | Headings + body on v1 fonts |
| status-badge | M | "Chờ xác nhận" chip solid pink + white text — tonal violation, **same class as `ux-flow-audit.md` C30** (already-fixed finding was about badge always showing `primary` regardless of status — this is the tonal-style follow-up, not a regression) |
| shape | M | Cards, buttons, chip all below v2 radii |
| contrast | M | Order ID/date/size/inactive-status text likely under AA vs `textSecondary` |
| color | M | Background light grey, not `#FBF6EF` |

## Profile (`28`, code: `FE/lib/screens/profile/profile_screen.dart`)

| Type | Sev | Finding |
|---|---|---|
| color | L | Active bottom-nav, "Khách hàng" chip bg, avatar bg all v1 pink |
| status-badge | L | "Khách hàng" chip solid pink + white text, measured contrast 2.76:1 — fails AA outright, not just a style preference |
| typography | L | Heading + menu-item text on v1 fonts |
| shape | M | Info card (~16dp) + chip (~20dp) below v2 (20/24 — card is at the boundary, chip needs the bump) |
| text-clip | M | Account email wraps awkwardly (single character orphaned on its own line) — cosmetic text-layout bug, independent of the token migration |
| color | M | Background white/light-grey, not `#FBF6EF` |

## Favorites (`29`, code: `FE/lib/screens/favorites/favorites_screen.dart`, empty state)

| Type | Sev | Finding |
|---|---|---|
| color | L | Background light-pink tint, not `#FBF6EF` |
| typography | L | AppBar title on Playfair Display |
| typography | M | Minor system-text font mismatch (status bar) — low-priority, likely unfixable at app level |
| color | M | Loading indicator on v1 pink |
| color | M | Icons need explicit `textPrimary`/`accent` mapping |
| **token-swap-only** | S | Model's own verdict: **this screen is structurally simple, real work is a token swap, not a layout rebuild** — matches Phase 1's T1 tier + 1 shared-widget (`product_card`) use |

## Notifications (`30`, code: `FE/lib/screens/notifications/notifications_screen.dart`)

| Type | Sev | Finding |
|---|---|---|
| status-badge | L | Success notification text/icon solid green, no tonal background — tonal violation |
| color | L | Bell icon + surrounding tint on v1 pink |
| typography | L | AppBar + body on v1 fonts |
| color | M | Background pure white, not `#FBF6EF` |
| contrast | M | Secondary status text + timestamp light-grey-on-white, likely under AA |
| shape | M | Bell-icon container radius v1-scale, needs `cardRadius`/`chipRadius` |

## Cross-Screen Pattern (dedup)

**Status-badge tonal violation appears on 7/13 captured customer screens** (CartItemEdit, ProductList, EditProfile, Orders, OrderDetail, Profile, Notifications) — same shared-`StatusBadge`-component fix identified in the manager findings; this single component change resolves the majority of `status-badge` findings across BOTH customer and manager surfaces (13 of 21 total status-badge findings pipeline-wide).

**2 screens have a "swap alone isn't enough" contrast finding** (ProductDetail, ProfileChip at 2.76:1) — v2 `primary` on white text does not universally clear AA; the reskin needs per-component contrast verification, not a blanket assumption that the new palette table's pairwise checks (done in Phase 3 for `textPrimary`/`background`/`surface`/button-text only) cover every composited UI state.

## Screen Verdict

| Screen | Verdict |
|---|---|
| Favorites | **token-swap-only** (T1 tier, matches Phase 1 prediction) |
| All other 12 captured customer screens | Real findings — color+typography sweep everywhere (expected, matches Phase 1's near-100% v1-token usage), several with genuine contrast/shape/touch-target issues beyond a simple swap |
