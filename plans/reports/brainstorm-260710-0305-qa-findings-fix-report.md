---
title: Brainstorm - Fix 5 QA Findings (Full-App QA 260710-0135)
date: 2026-07-10
branch: dev
commit-base: e24713c
source-report: plans/reports/260710-0135-bigstyle-full-app-qa/full-app-qa-report.md
status: approved
flags: none
---

# Brainstorm: Fix 5 QA Findings

## Problem Statement

Full-app runtime QA (260710-0135) passed all smoke flows but left 5 findings:
1 High (Google Maps blank), 2 Medium (manager order customer name, manager
dashboard stale after status update), 2 Low (Favorites nav highlight,
`orders.updated_at` not maintained). App otherwise stable: analyze clean,
20/20 tests, no crashes. This is polish scope, not firefighting.

## Project State (scouted)

- Flutter + BLoC (16 bloc modules, 141 dart files) + Supabase (RLS, RPC), SePay, google_maps_flutter.
- Recent hardening plans (stability, remote-data, role-ops) completed; leftover `partial` plans only lack runtime-smoke checkboxes largely covered by this QA run.
- Verified: `FE/android/app/src/main/AndroidManifest.xml` has NO `com.google.android.geo.API_KEY` metadata. `GOOGLE_MAPS_API_KEY` exists in `.env` only (Directions REST).
- Verified: `order_service.dart` `getAllOrders` joins `customer:profiles!orders_user_id_fkey(full_name)` but `getOrderById` does NOT — likely exact cause of "Không rõ" in manager detail. RLS on `profiles` is a second suspect to verify at runtime.
- Verified: `favorites_screen.dart:44` hardcodes `AppBottomNav(currentIndex: 3)` (Orders tab).
- Migrations live in `FE/supabase/migrations/` (latest 20260709100000).

## Decisions (user-approved)

| # | Finding | Decision |
|---|---------|----------|
| 1 | Maps blank (High) | Manifest placeholder: `<meta-data com.google.android.geo.API_KEY value="${GOOGLE_MAPS_API_KEY}">`, key read in `build.gradle` from `local.properties`/env, empty fallback, never committed. Rejected: secrets-gradle-plugin (extra dep, YAGNI), hardcode (leaks key). |
| 2 | Customer name "Không rõ" (Medium) | Add customer join to `getOrderById` mirroring `getAllOrders`; runtime-verify; if still null, add RLS policy migration letting manager/admin select `profiles.full_name`. Regression test: order with shipping_address lacking `name`. |
| 3 | Stale dashboard (Medium) | In `ManagerBloc._onUpdateOrderStatus` success path: patch matching `recentOrders` entry in place + refetch `dashboardStats` only (no full orders reload). Bloc test. |
| 4 | Favorites nav (Low) | User decision: Favorites = Profile subpage. Remove `AppBottomNav` from `FavoritesScreen`, keep back-button AppBar. Widget test asserts no bottom nav. |
| 5 | `orders.updated_at` (Low) | New migration: shared `set_updated_at()` trigger function + `BEFORE UPDATE` trigger on `orders`. Scope: orders only; note other tables for later. |

## Execution Order

1. Phase A: fixes 2+3 together (same manager order flow, shared tests).
2. Phase B: fix 1 (code ready anytime; runtime verify blocked on user-provided restricted key + Maps SDK for Android enabled in Google Cloud).
3. Phase C: fixes 4, 5.

Effort: ~0.5–1 day total.

## Risks

- Fix 2 may need DB policy migration if RLS blocks the join even after query fix — verify against remote before closing.
- Fix 1 unverifiable until a restricted Android Maps key exists (package name + SHA-1 restriction). Prepare code, verify on emulator after reinstall.
- Fix 3: keep `IndexedStack` behavior; only bloc state changes, no navigation rework.

## Success Criteria

- Map tiles + marker + route render on Store/Delivery screen (emulator, reinstalled APK).
- Manager order detail shows real customer name for orders of known profiles.
- Dashboard `Chờ xác nhận` card updates in-session after status change without pull-to-refresh.
- Favorites screen has no bottom nav; reachable from Profile.
- Updating order status bumps `orders.updated_at` (DB-level check).
- `flutter analyze` clean, all tests pass, new regression tests added for fixes 2, 3, 4.

## Unresolved Questions

- Which Google Cloud project owns the Maps key; who generates the SHA-1-restricted key (external to repo).
