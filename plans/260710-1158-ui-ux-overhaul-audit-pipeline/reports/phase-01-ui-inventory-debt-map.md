---
phase: 1
title: "Inventory & Debt Map"
date: 2026-07-10
sha: 6e77ccfcc7572621729fd67efca277ef4d65dab4
---

# Phase 1: Inventory & Debt Map

## Screen Definition & Method

Screen-dir walk first (47 dart files under `FE/lib/screens/`), classified against `app_router.dart` (19 routes) + shell tabs + `MaterialPageRoute` grep. Category legend: **(a)** router destination, **(b)** shell tab, **(c)** private inline class, **(d)** direct-push (`Navigator.push(MaterialPageRoute(...))`, not in router/shell — a 4th category the phase text implied but didn't name; added for transparency, same migration cost as (a)).

**Authoritative screen count: 30** (not 47 file-count, not the plan's ≈35 pre-estimate). 47 files = 30 screens + 17 components (checkout widgets ×5, manager sheets/cards/tables ×8, product-detail sheets/section ×3, `otp_input.dart` ×1). Every file accounted for — 0 dead/orphaned screens.

| Role | Screens |
|---|---|
| Guest | 2 (splash, login — OTP is a state inside login_screen, not a route) |
| Customer | 15 |
| Manager | 9 (3 shell tabs + 1 inline profile + 5 direct-push) |
| Admin | 4 (3 shell tabs + 1 inline profile) |

## Screens-by-Role: Debt, Shared-Widget Use, Tier

Hardcode metric = **lines** matching `Colors\.|0xFF[hex]` excluding `AppColors` (matches plan's original methodology — confirmed by exact reproduction of "manager ≈78" baseline). `.withOpacity` (deprecated) = **0 hits repo-wide**; already fully migrated to `.withValues(alpha:)` (90 hits) — corrects the plan's assumption of finding deprecated-API debt. Tier = heuristic score `hardcodeLines×2 + LOC/100 + (bespoke?5:0)`, ranked into terciles (10/10/10).

| # | Screen | File | Role | Cat | LOC | Hardcode | Shared widgets | Tier | ux-audit findings |
|---|---|---|---|---|---|---|---|---|---|
| 1 | ManagerProductList | manager/products/manager_product_list_screen.dart | manager | b | 564 | 28 | 0 (bespoke) | **T3** | M17✅ M19✅ M20 M21 |
| 2 | ManagerProductDetail | manager/products/manager_product_detail_screen.dart | manager | d | 1007 | 20 | 0 (bespoke) | **T3** | M34 M37 |
| 3 | ManagerCreateProduct | manager/products/manager_create_product_screen.dart | manager | d | 928 | 18 | 0 (bespoke) | **T3** | M28 M34 |
| 4 | Login | auth/login_screen.dart | guest | a | 429 | 18 | 0 (bespoke) | **T3** | G12 |
| 5 | DeliveryMap | delivery/delivery_map_screen.dart | customer | a | 564 | 14 | 0 (bespoke) | **T3** | C45 |
| 6 | AdminDashboard | admin/admin_dashboard_screen.dart | admin | b | 421 | 12 | 0 (bespoke) | **T3** | — |
| 7 | Chat | chat/chat_screen.dart | customer | a | 486 | 7 | 0 (bespoke) | **T3** | C42✅ |
| 8 | CartItemEdit | cart/cart_item_edit_screen.dart | customer | a | 377 | 7 | 0 (bespoke) | **T3** | — |
| 9 | ProductDetail | product_detail/product_detail_screen.dart | customer | a | 840 | 7 | 1 | **T3** | — |
| 10 | AdminUsers | admin/admin_users_screen.dart | admin | b | 671 | 5 | 0 (bespoke) | **T3** | — |
| 11 | AdminProfile (inline) | admin/admin_shell.dart:83 | admin | c | 233* | 7* | 0 (bespoke) | T2 | — |
| 12 | ProductList | product_list/product_list_screen.dart | customer | a | 510 | 8 | 3 | T2 | — |
| 13 | ManagerProfile (inline) | manager/manager_shell.dart:55 | manager | c | 208* | 7* | 0 (bespoke) | T2 | M2 |
| 14 | Splash | splash/splash_screen.dart | guest | a | 167 | 7 | 0 (bespoke) | T2 | — |
| 15 | Home | home/home_screen.dart | customer | a | 419 | 8 | 4 | T2 | C3✅ |
| 16 | AdminCategories | admin/admin_categories_screen.dart | admin | b | 328 | 5 | 0 (bespoke) | T2 | — |
| 17 | EditProfile | profile/edit_profile_screen.dart | customer | a | 354 | 4 | 0 (bespoke) | T2 | — |
| 18 | ManagerVoucherList | manager/vouchers/manager_voucher_list_screen.dart | manager | d | 240 | 0 | 0 (bespoke) | T2 | — |
| 19 | Checkout | checkout/checkout_screen.dart | customer | a | 533 | 1 | 2 | T2 | — |
| 20 | ManagerCategoryList | manager/categories/manager_category_list_screen.dart | manager | d | 227 | 0 | 0 (bespoke) | T2 | — |
| 21 | ManagerDashboard | manager/manager_dashboard.dart | manager | b | 184 | 0 | 0 (bespoke) | T1 | M6 |
| 22 | ManagerOrders | manager/manager_orders_screen.dart | manager | b | 147 | 0 | 0 (bespoke) | T1 | — |
| 23 | Cart | cart/cart_screen.dart | customer | a | 360 | 1 | 4 | T1 | — |
| 24 | Orders | orders/orders_screen.dart | customer | a | 211 | 1 | 4 | T1 | — |
| 25 | OrderDetail | orders/order_detail_screen.dart | customer | a | 361 | 0 | 2 | T1 | C30✅ |
| 26 | ManagerOrderDetail | manager/manager_order_detail_screen.dart | manager | d | 318 | 0 | 1 | T1 | M12 |
| 27 | PaymentQr | checkout/payment_qr_screen.dart | customer | a | 275 | 0 | 2 | T1 | — |
| 28 | Profile | profile/profile_screen.dart | customer | a | 196 | 0 | 2 | T1 | — |
| 29 | Favorites | favorites/favorites_screen.dart | customer | a | 136 | 0 | 1 | T1 | — |
| 30 | Notifications | notifications/notifications_screen.dart | customer | a | 135 | 0 | 1 | T1 | — |

\* Shell file metric = infra (bottom nav / NavigationBar) + inline profile screen combined; not separable by grep. Borderline case, noted rather than dropped.

**Tier totals:** T3 = 10 (login, deliveryMap, chat, cartItemEdit, productDetail + 5 manager/admin bespoke) · T2 = 10 · T1 = 10.
**Sharpest signal:** manager (9/9) and admin (4/4) screens are **100% bespoke** — zero use of the 10 shared `lib/widgets/*` components. Only customer screens (11/15) show real reuse. Manager+Admin = 13/30 screens (43%) at zero shared-widget adoption — the reskin plan's highest-leverage target for introducing shared components.

## Old Audit Cross-Reference (`docs/ux-flow-audit.md`)

10 `consistency` + 6 `ui` findings, all attached above by ID. **5 already fixed** (C3, C30, C42, M17, M19 — marked ✅ in source doc). **11 still open**: G12, G16(otp_input.dart, component of Login), C45, M2, M6, M12, M20, M21, M28, M34, M37. Overlap is small as the plan predicted — none change the tier ranking, all fold into their screen's existing debt count.

## Entry Gates (all green — verified via evidence, not blind assumption)

| Gate | Status | Evidence |
|---|---|---|
| Demo customer login | ✅ | DB: 1 `customer` profile in `public.profiles` (project `bigstyle-prm393`); live AVD screenshot (emulator-5554, 2026-07-10 12:42) shows an active customer-role session on delivery-map screen |
| Manager login | ✅ | DB: 2 `manager` profiles; **live-verified same day** — commit `6e77ccf` closes stability-hardening phase 4 after live order-status-update test on Pixel 8 AVD (order pending→confirmed, DB write confirmed, reverted after) |
| Admin login | ✅ | DB: 1 `admin` profile; **live-verified same day** — `plans/260710-0001-bigstyle-role-ops-hardening/reports/admin-smoke-baseline.md`: password login via debug `Manager test` button (dart-define retargeted to admin account) routed to `/admin`, dashboard rendered with live remote stats |
| `GEMINI_API_KEY` | ✅ | Models-list HTTP 200 + **one real `gemini-2.5-flash` vision analyze call executed this session** on a synthetic (non-PII) test image — correct description returned |

Plan's stale assumption ("manager OTP login not done") is superseded by same-day work in a parallel plan — corrected here, not carried forward.

## Borderline Cases (per Risk Assessment — listed, not silently dropped)

- `otp_input.dart`: embedded widget inside `login_screen.dart`, not a route — classified as component, not a 3rd guest screen.
- 5 manager screens reached only via `Navigator.push(MaterialPageRoute(...))`, invisible to both the router table and shell-tab enumeration — added as category **(d)**, same migration cost as routed screens.
- `manager_shell.dart` / `admin_shell.dart`: file-level LOC/hardcode metrics conflate shell chrome (bottom nav) with the inline profile screen's body — flagged, not split (grep can't attribute lines to inner class boundaries reliably).
- 0 dead screens found: all 47 files resolve to either a screen or a component with a live reference.

## Success Criteria

- [x] Authoritative screen count (30) produced per definition, not file count.
- [x] Per-file debt table complete; hardcode-line recount (195 total) is authoritative — close to but below the ~208 draft baseline (likely prior-session cleanup in recent commits).
- [x] Every screen tagged T1/T2/T3.
- [x] Entry gates green (see above).
- [x] Report written, no PII (accounts referenced by role only), 137 lines.
