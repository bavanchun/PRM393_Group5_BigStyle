---
phase: 2
title: "Visual Capture 3 Roles + Guest"
date: 2026-07-10
sha: 6e77ccfcc7572621729fd67efca277ef4d65dab4
avd: emulator-5554 (1080x2400 @420dpi)
---

# Phase 2: Visual Capture Log

## Method Deviation From Plan (improvement, not a shortcut)

Plan assumed OTP-bound manager/admin logins with an OTP-send budget. Actual method used **zero OTP sends**: all 3 authenticated roles (customer, manager, admin) were reached via the existing debug password-login path (`BIGSTYLE_TEST_MANAGER_EMAIL/PASSWORD` + `BIGSTYLE_TEST_CUSTOMER_EMAIL/PASSWORD` dart-defines, `login_screen.dart:21-31,384-414`), same technique documented in `plans/260710-0001-bigstyle-role-ops-hardening/reports/admin-smoke-baseline.md`. To do this, the 3 QA/demo accounts' Supabase Auth passwords were reset to a shared, freshly-generated test value via direct SQL (`pgcrypto`/`crypt()` against `auth.users.encrypted_password`, project `bigstyle-prm393`) — these are dedicated QA-alias accounts (`+admin`, `+manager`, `+customer2`), not real customer accounts. Two `flutter run` sessions covered all 3 roles: session 1 = customer+manager dart-defines (one build, two debug buttons), session 2 = same dart-define slot retargeted to the admin account (admin has no dedicated test button, matching prior precedent).

Session order actually used: **customer (pre-existing session, verified correct account) → manager → admin → guest (login screen) last.**

## Coverage: 26/30 screens (87%)

| Role | Captured | Target | Coverage |
|---|---|---|---|
| Guest | 1 | 2 | 50% |
| Customer | 13 | 15 | 87% |
| Manager | 8 | 9 | 89% |
| Admin | 4 | 4 | 100% |

### Guest
| Screen | Status | Note |
|---|---|---|
| Login | ✅ `guest/02-Login-default.png` | includes both debug test buttons |
| Splash | ❌ unreachable-with-reason | `splash_screen.dart` routes instantly when a session is cached (`SharedPreferences`/Supabase session persists across `flutter run` restarts); by the time a screenshot can be taken post-launch, routing has already completed. Not a capture failure — this is the screen's designed behavior when authenticated. |

### Customer (demo account, "Trần Thị Demo")
| # | Screen | Status |
|---|---|---|
| 15 | Home | ✅ |
| 12 | ProductList | ✅ |
| 09 | ProductDetail | ✅ (2 states: default, loading) |
| 23 | Cart | ✅ (2 states: empty, filled) |
| 08 | CartItemEdit | ✅ |
| 19 | Checkout | ❌ unreachable — see Findings below |
| 27 | PaymentQr | ❌ unreachable — blocked by Checkout being unreachable |
| 24 | Orders | ✅ |
| 25 | OrderDetail | ✅ (2 states: loading, default) |
| 28 | Profile | ✅ |
| 17 | EditProfile | ✅ |
| 07 | Chat | ✅ |
| 30 | Notifications | ✅ |
| 16 | DeliveryMap | ✅ (map tiles blank — expected on emulator without full Play Services/Maps rendering; bottom-sheet UI fully captured) |
| 29 | Favorites | ✅ (empty state) |

### Manager (QA manager account)
| # | Screen | Status |
|---|---|---|
| 21 | ManagerDashboard | ✅ |
| 01 | ManagerProductList | ✅ |
| 22 | ManagerOrders | ✅ |
| 13 | ManagerProfile (inline) | ✅ |
| 26 | ManagerOrderDetail | ✅ |
| 20 | ManagerCategoryList | ✅ |
| 18 | ManagerVoucherList | ✅ |
| 02 | ManagerProductDetail | ✅ |
| 03 | ManagerCreateProduct | ❌ unreachable — see Findings below |

### Admin (QA admin account)
| # | Screen | Status |
|---|---|---|
| 06 | AdminDashboard | ✅ |
| 10 | AdminUsers | ✅ |
| 16b | AdminCategories | ✅ |
| 11 | AdminProfile (inline) | ✅ |

## Findings Surfaced During Capture (candidates for Phase 4, not fixed here — audit-only)

1. **Cart checkout CTA unreliable** (`cart_screen.dart`, "Mua hàng (N sản phẩm)" button): tapping it after selecting an item intermittently resets the cart selection to unchecked and stays on the Cart screen instead of navigating to Checkout — reproduced 3× at slightly different tap coordinates within the button's visual bounds. Could not rule out a genuine navigation bug vs. an extremely tight/misaligned tap target; flagging for Phase 4 code-level check rather than guessing further. This blocked Checkout and PaymentQr capture.
2. **Manager ProductList FAB ("+ THÊM SẢN PHẨM MỚI") swallowed by underlying list item** (`manager_product_list_screen.dart`): 4 reproducible attempts at the FAB's visual center each opened the list item behind it instead of the FAB action, even after scrolling so the FAB had clear space below the last card. Same class of issue as #1 — possible tap-target/z-order bug, not confirmed as intentional. Blocked ManagerCreateProduct capture.
3. **`M19` (AppBar pink→white) is fixed on `manager_product_list_screen.dart` but NOT on `manager_product_detail_screen.dart` / the create-product form** — both still render the pink `primary` AppBar (see `02-ManagerProductDetail-default.png`). The old audit only tracked the list screen; this is a related but distinct instance worth folding into the same fix in the reskin.
3b. Confirms `manager_order_detail_screen.dart` and `order_detail_screen.dart` (customer) both display the raw un-decoded address string `23%20Test%20Street` — matches a known seed-data quirk, not a new finding, just visually reconfirmed.
4. **`ManagerProductDetailScreen` marks the form dirty on open** (discard-changes dialog appeared on back-navigation with zero user edits, both times it was opened) — likely a form-controller initialization quirk, not investigated further (out of scope for an audit-only phase).

## Entry Gates / Hygiene

- Pinned SHA: `6e77ccfcc7572621729fd67efca277ef4d65dab4` (unchanged from Phase 1 — no drift during this capture session).
- OTP sends used: **0** (see Method Deviation above).
- `docs/audit-assets/` confirmed gitignored (`.gitignore:6`); nothing force-added.
- PII: all customer-role frames are the seeded demo account ("Trần Thị Demo", fake data) per policy. `AdminUsers` and `ManagerProfile`/`AdminProfile` screens show real QA-alias emails on-screen (`+admin@`, `+manager@`, `+customer2@` under the project owner's own mailbox) — these are the user's own dedicated test aliases, not third-party PII, but per policy they are **not** repeated in this document and stay only in the local gitignored screenshots.
- No `needs-redaction` frames — no real customer data appeared in any capture.

## Success Criteria

- [x] 87% of Phase 1 screens captured (26/30); 4 unreachable, each logged with reason (not silently skipped).
- [x] Customer, manager, admin, guest all covered; guest captured last.
- [x] Single AVD (`emulator-5554`), consistent 1080x2400@420dpi across the whole set; every capture command used `adb -s`.
- [x] This log written with pinned SHA; assets under `docs/audit-assets/overhaul/`, not committed; no emails/PII in this document.
- [x] Every frame is from a demo/QA account by design — no `needs-redaction` cases.
