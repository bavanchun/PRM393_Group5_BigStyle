---
phase: 3
title: UI & Dashboard Wiring
status: completed
effort: ''
---

# Phase 3: UI & Dashboard Wiring

## Overview
Build the category list screen + create/edit bottom sheet, and wire the
dashboard "Danh mục" quick action to open it (removing the coming-soon path).

## Requirements
- Functional: list categories (name, product count, active badge, image thumb);
  FAB to add; tap row → edit sheet; edit sheet supports name/image/sort_order/
  is_active + soft-delete; success/error snackbars.
- Non-functional: match visual + structural patterns of
  `manager_orders_screen.dart` (list + `BlocBuilder`) and
  `order_status_update_sheet.dart` (modal bottom sheet with submit/error state).
  Use `app_colors`/`app_spacing`/`app_typography` tokens.

## Architecture
- List screen dispatches `LoadManagerCategoriesEvent` in `initState`; renders
  loading/empty/error/list from bloc state (mirror manager orders screen).
- Edit sheet: for create, empty model; for edit, prefilled. On submit dispatch
  Create/Update; on delete dispatch SoftDelete with a confirm dialog (reuse the
  destructive-confirm pattern from `order_status_update_sheet`).
- Image: reuse the product create screen's image picker/upload approach
  (`UploadManagerCategoryImageEvent` → public URL into the model).

## Related Code Files
- Create: `FE/lib/screens/manager/categories/manager_category_list_screen.dart`
- Create: `FE/lib/screens/manager/categories/manager_category_edit_sheet.dart`
  (expose `showManagerCategoryEditSheet(context, {CategoryModel? existing})`).
- Modify: `FE/lib/screens/manager/manager_dashboard_widgets.dart` — the "Danh mục"
  quick action gets an `onTap`/callback that navigates (instead of the shared
  `onComingSoon`). Prefer adding an `onManageCategories` callback to
  `ManagerQuickActions` so "Thêm sản phẩm"/"Khuyến mãi" keep their current
  behavior untouched.
- Modify: `FE/lib/screens/manager/manager_dashboard.dart` — pass a navigate
  callback that pushes `ManagerCategoryListScreen`.

## Implementation Steps
1. Build list screen from the manager-orders template (BlocBuilder + states).
2. Build edit bottom sheet (create/edit) with fields + submit/delete + confirm.
3. Add `onManageCategories` to `ManagerQuickActions`; route "Danh mục" to it.
4. In dashboard, push `ManagerCategoryListScreen` on that callback.
5. `flutter analyze` clean.

## Success Criteria
- [ ] "Danh mục" opens the list (no "Tính năng đang phát triển").
- [ ] FAB opens create sheet; save adds a category to the list.
- [ ] Row tap opens edit sheet; save updates the row.
- [ ] Soft-delete (with confirm) removes it from the active list.
- [ ] "Thêm sản phẩm" + "Khuyến mãi" quick actions unchanged.

## Risk Assessment
- Layout pitfalls like the M7b `SizedBox`+button collapse — use `styleFrom`
  min sizes, not fixed-height `SizedBox` wrappers, for sheet buttons.
- Only "Danh mục" should change; keep the other two quick actions on
  `onComingSoon` to avoid scope creep.
