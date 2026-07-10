---
phase: 2
title: "FAB hero tags"
status: done
effort: "15m"
priority: P1
dependencies: []
---

# Phase 2: FAB hero tags

## Overview
Give every `FloatingActionButton` a unique `heroTag`. **6 FABs** (red-team corrected the original census of 5) use Flutter's default tag; `AdminShell`'s `IndexedStack` keeps Users + Categories mounted simultaneously → real assertion at every admin login (confirmed in `flutter run` log: "There are multiple heroes that share the same tag"). Manager side is the latent variant: product-list FAB stays alive under `Navigator.push`ed voucher/category screens whose FABs share the default tag — route pushes DO run hero flights. The delivery-map small FAB is today the only FAB on its route (no current collision) but is tagged anyway so the crash class can't silently return.

## Requirements
- Functional: no hero-tag collisions anywhere; no hero-morph animation between these FABs (none is intended).
- Non-functional: zero visual/behavior change otherwise.

## Related Code Files
Modify (add one `heroTag:` line each):
- `FE/lib/screens/admin/admin_users_screen.dart:30` → `heroTag: 'admin-users-fab'`
- `FE/lib/screens/admin/admin_categories_screen.dart:26` → `heroTag: 'admin-categories-fab'`
- `FE/lib/screens/manager/products/manager_product_list_screen.dart:195` → `heroTag: 'manager-products-fab'`
- `FE/lib/screens/manager/vouchers/manager_voucher_list_screen.dart:41` → `heroTag: 'manager-vouchers-fab'`
- `FE/lib/screens/manager/categories/manager_category_list_screen.dart:41` → `heroTag: 'manager-categories-fab'`
- `FE/lib/screens/delivery/delivery_map_screen.dart:364` (`FloatingActionButton.small`) → `heroTag: 'delivery-map-recenter-fab'`

## Implementation Steps
1. Add the 6 `heroTag` lines.
2. `flutter analyze` + `flutter test`.
3. Emulator: login as admin (test creds via dart-define) → assert no "multiple heroes" in log; as manager, open Danh mục + Khuyến mãi from dashboard quick actions (pushes over product-list FAB) → log clean.
4. Commit.

## Success Criteria
- [ ] Repo-wide census closed: `grep -rn "FloatingActionButton" FE/lib --include="*.dart" | wc -l` equals `grep -rn "heroTag:" FE/lib --include="*.dart" | wc -l` construction-site count (every FAB constructor has a tag; grep covers ALL of FE/lib, not just admin/manager)
- [ ] Admin login + manager voucher/category push produce no hero exception in log
- [ ] analyze/tests green; 1 commit

## Risk Assessment
Trivial. String tags are only compared for uniqueness within a route subtree.
